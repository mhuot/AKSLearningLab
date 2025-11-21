{{- define "orders-api.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "orders-api.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "orders-api.name" .) -}}
{{- end -}}

{{- define "orders-api.labels" -}}
helm.sh/chart: {{ include "orders-api.chart" . }}
app.kubernetes.io/name: {{ include "orders-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "orders-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orders-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "orders-api.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
