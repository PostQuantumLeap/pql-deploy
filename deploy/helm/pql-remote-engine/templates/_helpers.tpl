{{- define "engine.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "engine.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "engine.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "engine.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "engine.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "engine.selectorLabels" -}}
app.kubernetes.io/name: {{ include "engine.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "engine.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ $tag }}
{{- end -}}
{{- end -}}

{{/*
  The relay TLS mode the engine receives. ONE definition for the guard and the
  env entry, so the value refused and the value rendered cannot drift apart.

  ABSENT means `auto`, the chart default. `helm upgrade --reuse-values` (the
  command the Update dialog prints) feeds a release its OLD values instead of
  this chart's defaults, so every release installed from chart 0.2.0 arrives
  with no `relay.tls` key at all; refusing that would break the update of every
  existing engine over a value its operator never set. Only nil and "" count as
  absent, not `default`'s notion of empty: `tls: off` in a values file reaches
  the template as the boolean false, and that was written, so it is refused.
*/}}
{{- define "engine.relayTls" -}}
{{- if kindIs "invalid" .Values.relay.tls -}}
auto
{{- else -}}
{{- default "auto" (toString .Values.relay.tls) -}}
{{- end -}}
{{- end -}}

{{- define "engine.validate" -}}
{{- if not .Values.serverUrl -}}
{{- fail "\n\nserverUrl is not set. An engine has to know where to report:\n  --set serverUrl=https://pql.example.com\n" -}}
{{- end -}}
{{- if not (or (hasPrefix "https://" .Values.serverUrl) (hasPrefix "http://" .Values.serverUrl)) -}}
{{- fail (printf "serverUrl must include a scheme, got %q" .Values.serverUrl) -}}
{{- end -}}
{{/*
  http:// reaches PQL over cleartext, carrying the engine token in a header on
  every request. Refused rather than warned about: an engine is deployed once
  and lives in a segment nobody revisits, so a warning at install time is read
  by nobody a year later.
*/}}
{{- if hasPrefix "http://" .Values.serverUrl -}}
{{- fail "\n\nserverUrl is http://. The engine token travels on every request, so\ncleartext would hand it to anything on the path between this segment and PQL.\nUse https://, with `caBundle.configMap` if PQL serves a private CA.\n" -}}
{{- end -}}
{{- if not .Values.existingSecret -}}
{{- fail "\n\nexistingSecret is not set. The engine token authenticates this engine to your\ninstallation, so it is not a values-file field:\n\n  kubectl create secret generic pql-engine-token \\\n    --from-literal=PQL_ENGINE_TOKEN='<shown once by the setup wizard>'\n\n  --set existingSecret=pql-engine-token\n" -}}
{{- end -}}
{{- if not (has .Values.autoUpdate (list "off" "notify" "auto")) -}}
{{- fail (printf "autoUpdate must be off, notify or auto, got %q" .Values.autoUpdate) -}}
{{- end -}}
{{- if and .Values.relay.port (gt (int .Values.relay.port) 0) (not .Values.relay.publicName) -}}
{{- fail "\n\nrelay.port is set but relay.publicName is empty.\n\nThe relay hands scanning hosts an address to dial back on, and that address is\nthis value — not the Service name, which hosts outside the cluster cannot\nresolve. Without it they receive an address that does not answer.\n" -}}
{{- end -}}
{{- if and .Values.engineId (not (regexMatch "^[0-9]+$" (toString .Values.engineId))) -}}
{{- fail (printf "\n\nengineId must be the engine's numeric id from PQL, got %q.\n\nIt is the number in the engine's row, not its name. Quote it (\"7\") so Helm\ndoes not turn a large id into a float.\n" (toString .Values.engineId)) -}}
{{- end -}}
{{/*
  A shape check, not `len`: Go's `len` counts BYTES, so it both refused short
  non-ASCII labels as "too long" and let `Zürich` through — a label the engine
  sends in the `x-pql-engine-instance` header, where its HTTP client refuses to
  encode anything but ASCII, failing every connect.
*/}}
{{- if not (regexMatch "^[ -~]{0,64}$" (toString (default "" .Values.instanceLabel))) -}}
{{- fail (printf "\n\ninstanceLabel must be at most 64 printable ASCII characters, got %q.\n\nPQL binds the token to this label in a 64-character column, and the engine\nsends it in an HTTP header that its client encodes as ASCII only. A longer or\nnon-ASCII label fails the first time the engine connects.\n" (toString .Values.instanceLabel)) -}}
{{- end -}}
{{- if not (has (include "engine.relayTls" .) (list "auto" "sidecar")) -}}
{{- fail (printf "relay.tls must be auto or sidecar, got %q" (toString .Values.relay.tls)) -}}
{{- end -}}
{{- end -}}
