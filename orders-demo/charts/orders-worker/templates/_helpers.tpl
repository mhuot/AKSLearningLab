{{- define "orders-worker.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "orders-worker.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "orders-worker.name" .) -}}
{{- end -}}

{{- define "orders-worker.labels" -}}
helm.sh/chart: {{ include "orders-worker.chart" . }}
app.kubernetes.io/name: {{ include "orders-worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "orders-worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orders-worker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "orders-worker.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
