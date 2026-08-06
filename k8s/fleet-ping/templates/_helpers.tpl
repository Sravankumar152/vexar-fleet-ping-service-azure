{{- define "fleet-ping.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "fleet-ping.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "fleet-ping.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "fleet-ping.labels" -}}
app.kubernetes.io/name: {{ include "fleet-ping.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "fleet-ping.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fleet-ping.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
