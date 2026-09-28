# Remote engine on Kubernetes

A remote engine scans a segment PQL itself cannot reach — a DMZ, a branch
network, a cloud VPC. It **dials out** to PQL and never accepts an inbound
connection from it, which is what makes it deployable behind a firewall that
would refuse one.

This is not the PQL application. Install [`../pql`](../pql/README.md) wherever
PQL lives; install this in the segment.

```bash
kubectl create namespace pql-engine

kubectl -n pql-engine create secret generic pql-engine-token \
  --from-literal=PQL_ENGINE_TOKEN='<shown once by the setup wizard>'

helm install engine deploy/helm/pql-remote-engine -n pql-engine \
  --set serverUrl=https://pql.example.com \
  --set existingSecret=pql-engine-token \
  --set engineName=dmz-frankfurt
```

The namespace is created first and the Secret is created **in it**. Secrets are
namespaced: left in whatever namespace the kubeconfig happens to point at, the
Deployment's `secretKeyRef` resolves to nothing and the pod never leaves
`CreateContainerConfigError` — with nothing in the message naming the namespace
as the reason. `helm install` then has a namespace to install into, so
`--create-namespace` is no longer needed (keeping it does no harm).

The engine runs its own preflight at startup and names the step that failed:

```
preflight resolve  ok   pql.example.com resolves
preflight connect  ok   pql.example.com:443 accepts
preflight tls      ok   certificate verified
preflight token    ok
```

## What the chart refuses

- **`serverUrl` over `http://`.** The engine token travels on every request, so
  cleartext hands it to anything on the path. Refused rather than warned about:
  an engine is deployed once into a segment nobody revisits, so an install-time
  warning is read by nobody a year later. Use `https://`, with
  `caBundle.configMap` if PQL serves a private CA.
- **A token as a values field.** It authenticates this engine for as long as it
  is valid; a value lands in `helm get values` and in every CI log that renders
  the chart. `existingSecret` only.
- **A relay port with no `relay.publicName`.** The relay hands scanning hosts an
  address to dial back on. That address is `publicName`, not the Service name —
  those hosts are outside the cluster and cannot resolve cluster DNS. Without it
  they are handed something that does not answer.
- `serverUrl` with no scheme, and an unknown `autoUpdate` value.
- **A non-numeric `engineId`.** It is compared with the engine's row number to
  guard the relay's TLS material. Quote it: Helm reads a bare number from a
  values file as a float and prints a large id as `1.2345678e+07`, which is then
  refused rather than silently mismatched (measured).
- **An `instanceLabel` that is not printable ASCII, or is over 64 characters.**
  64 is the width of the column PQL binds the label into on the first connect,
  and the engine sends the label as an HTTP header its client encodes as ASCII
  only, so `Zürich` would fail every connect.
- **An unknown `relay.tls`.** The engine reads an unknown mode as `auto`, so a
  typo would otherwise pass without doing what was written.

## Updates

`autoUpdate` is `notify` by default: PQL says a newer build exists and nothing
moves. `auto` makes the engine **exit** when one is advertised, so the kubelet
replaces it — and the chart then sets `imagePullPolicy: Always` for you, because
without it the engine restarts onto the same image, finds itself stale, and
exits again. That crash-loop reads as a broken engine rather than a missing pull
policy.

Decide it deliberately. These containers sit where nobody has a shell.

`PQL_ENGINE_PLATFORM` is stated as `kubernetes` rather than left to
autodetection. The engine can infer it from `KUBERNETES_SERVICE_HOST`, which is
real but circumstantial — a sidecar-injecting mesh or a bare `kubectl run` can
make it lie — and the platform decides what an update actually does.

## From the setup wizard

**Admin → Bifröst → New Bifröst engine → Kubernetes** generates one engine's
install: the Secret command (the token goes into the Secret and never into a
values file), a CA ConfigMap command when you attached a CA, the commands that
mirror the image into your registry, a `values.yaml`, and the `helm install`
that uses it. The token is shown on that screen only — PQL keeps a hash.

It always sets three values a hand-written install tends to leave out:

- `engineId` → `PQL_ENGINE_ID`, quoted. The relay's TLS ownership key.
- `instanceLabel` → `PQL_ENGINE_INSTANCE`. PQL binds the token to the first
  label it sees and refuses any other afterwards.
- `relay.tls` → `PQL_RELAY_TLS`, always `auto`: the engine terminates TLS with
  its own key and install commands pin its fingerprint. `sidecar` is only for a
  terminator you run in front of the Service yourself.

## The relay Service

With `relay.port` set the chart creates `<release>-pql-remote-engine-relay`. The
hosts that run the client scanner are outside the cluster, so the chart default
`ClusterIP` is unreachable for them: use `LoadBalancer` (the wizard's default) or
`NodePort`, and make `relay.publicName` resolve to the address that Service is
given. The relay has not yet been verified on a cluster.

## Mirroring the image

A kubelet pulls from a registry. It cannot load the archive PQL hosts, and no
public registry carries the engine yet, so mirror it once per engine build from
any machine with Docker that reaches both PQL and your registry:

```bash
curl -fsSL -H "Authorization: Bearer <engine token>" \
  https://pql.example.com/api/remote-engine/image/linux-amd64 \
  | docker load &&
docker tag pql-remote-engine:local registry.example.com/pql/remote-engine:1.3.0 &&
docker push registry.example.com/pql/remote-engine:1.3.0
```

**The `&&` are load-bearing.** `docker push` pushes whatever this machine holds
under that name. Joined by bare newlines, a download refused with a 401 or cut
short leaves the PREVIOUS build under `pql-remote-engine:local`, and the tag and
the push run anyway — the old build goes out under the new version's tag, and
the chart's `IfNotPresent` pull policy then keeps it cached on the nodes after a
correct re-push (reproduced under sh, bash and zsh, 2026-09-15). Chained, a
failure exits non-zero with nothing after it. The wizard's generated mirror is
chained the same way, by `engineKubernetes.ts`'s `chained()`.

The amd64 and arm64 archives load under the SAME tag, so push one architecture
per tag or assemble a multi-arch manifest yourself; the wizard pins the pod with
`nodeSelector: {kubernetes.io/arch: …}` to the architecture it mirrored. The tag
must be the engine build PQL advertises. For the next build the engine's Update
dialog prints `helm upgrade <release> … --reuse-values --set image.tag=<build>`.

## One engine per token

`replicas` is not a value. The token names one engine in PQL's console; a second
Pod sharing it is the same engine claiming work twice, sending two heartbeats
and reporting two versions. For more capacity, issue another token and install
this chart again under a different release name.

## Verified

Against a live PQL on a kind cluster, 2026-08-31: the engine started from this
chart's rendered Deployment, resolved and connected to PQL over TLS with a CA
bundle mounted from `caBundle.configMap`, verified the certificate, and was
refused with a 401 on a deliberately invalid token — which is the whole wiring
proven, with the only failure being the one that was engineered.

Not yet verified: a real scan through an engine deployed this way, and the relay
listener.
