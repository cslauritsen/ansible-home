{{- define "apache-james.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "apache-james.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "apache-james.chart" -}}
{{- .Chart.Name | replace "-" " " -}}
{{- end -}}

{{- define "apache-james.version" -}}
{{- .Chart.Version -}}
{{- end -}}

{{- define "apache-james.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "apache-james.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
