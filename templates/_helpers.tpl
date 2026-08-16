{{/*
_helpers.tpl — files starting with `_` produce NO Kubernetes manifest. They hold
`define` blocks you `include` elsewhere. This is how you stay DRY.

Reminder on Go template syntax:
  {{ }}    an action
  {{- }}   trim preceding whitespace   -}}  trim following
  |        pipe: {{ .Values.x | quote }}
  .        the current scope — NOT always the root!
  $        the ROOT scope, always. Needed inside range/with.
*/}}

{{/*
Chart name, overridable.
*/}}
{{- define "fastapiredis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name — the standard Helm idiom.

  trunc 63       : Kubernetes names are limited to 63 chars (DNS label).
  trimSuffix "-" : trunc can leave a trailing dash, which is an INVALID name.

If the release name already contains the chart name, don't repeat it:
release "nrmr" + chart "nrmr" -> "nrmr", not "nrmr-nrmr".
*/}}
{{- define "fastapiredis.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "fastapiredis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
COMMON LABELS — applied to every object.
These are the conventional labels from step 3.
*/}}
{{- define "fastapiredis.labels" -}}
helm.sh/chart: {{ include "fastapiredis.chart" . }}
{{ include "fastapiredis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: fastapi-with-redis
{{- end }}

{{/*
SELECTOR LABELS — the subset used in selectors.

CRITICAL: this must be a STRICT SUBSET of nrmr.labels, and must NEVER include
anything volatile like version or chart. A Deployment's spec.selector is
IMMUTABLE (step 3) — put app.kubernetes.io/version in here and every chart
upgrade fails with "field is immutable" and needs a delete+recreate.
*/}}
{{- define "fastapiredis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fastapiredis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Per-component selector labels. Call with a dict:
  {{- include "fastapiredis.componentSelectorLabels" (dict "ctx" . "component" "app") }}

`.` inside a define is the scope PASSED IN, not the root — hence the dict
pattern to smuggle both the root context and an argument through.
*/}}
{{- define "fastapiredis.componentSelectorLabels" -}}
{{ include "fastapiredis.selectorLabels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "fastapiredis.componentLabels" -}}
{{ include "fastapiredis.labels" .ctx }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
The name of the Secret to use — either one the user made, or ours.
Lets `auth.existingSecret` transparently replace the templated Secret.
*/}}
{{- define "fastapiredis.secretName" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecret }}
{{- else }}
{{- printf "%s-auth" (include "fastapiredis.fullname" .) }}
{{- end }}
{{- end }}

{{- define "fastapiredis.configMapName" -}}
{{- printf "%s-config" (include "fastapiredis.fullname" .) }}
{{- end }}

{{/*
Service names — these become the DNS names the app connects to (step 6).
*/}}
{{- define "fastapiredis.redisServiceName" -}}
{{- printf "%s-redis" (include "fastapiredis.fullname" .) }}
{{- end }}

{{/*
The app image ref. `.Values.app.image.tag` falls back to Chart.appVersion,
which keeps the shipped version declared in exactly one place.
*/}}
{{- define "fastapiredis.appImage" -}}
{{- $tag := .Values.app.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.app.image.repository $tag -}}
{{- end }}
