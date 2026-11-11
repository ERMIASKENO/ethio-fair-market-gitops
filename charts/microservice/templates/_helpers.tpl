{{/* Name of every object = service name */}}
{{- define "ms.name" -}}
{{- required "values.name is required" .Values.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Recommended Kubernetes labels */}}
{{- define "ms.labels" -}}
app.kubernetes.io/name: {{ include "ms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/component: {{ .Values.tier }}
app.kubernetes.io/part-of: {{ .Values.partOf }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
efm.io/team: {{ .Values.team }}
{{- end -}}

{{/* Stable selector labels (must never change after the first install) */}}
{{- define "ms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* image reference: repository:tag or repository@digest */}}
{{- define "ms.image" -}}
{{- $repo := required "values.image.repository is required" .Values.image.repository -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" $repo .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" $repo (required "values.image.tag is required" .Values.image.tag) -}}
{{- end -}}
{{- end -}}

{{- define "ms.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}{{ include "ms.name" . }}{{- else -}}default{{- end -}}
{{- end -}}
