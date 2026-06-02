{{/*
Expand the name of the chart.
*/}}
{{- define "thoughtsapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "thoughtsapp.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "thoughtsapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "thoughtsapp.labels" -}}
helm.sh/chart: {{ include "thoughtsapp.chart" . }}
{{ include "thoughtsapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: thoughtsapp
{{- end }}

{{/*
Selector labels
*/}}
{{- define "thoughtsapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "thoughtsapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PostgreSQL connection string
*/}}
{{- define "thoughtsapp.postgresql.url" -}}
jdbc:postgresql://postgresql:5432/{{ .Values.postgresql.database }}
{{- end }}

{{/*
Kafka bootstrap servers
*/}}
{{- define "thoughtsapp.kafka.bootstrap" -}}
thoughtsapp-kafka-kafka-bootstrap:9092
{{- end }}
