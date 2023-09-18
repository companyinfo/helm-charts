{{/*
Create the name of the service account to use
*/}}
{{- define "helmet.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the unordered list from a dictionary
*/}}
{{- define "helmet.dictToArray" -}}
{{- range $k, $v := . }}
- name: {{ $k }}
  value: {{ quote $v }}
{{- end -}}
{{- end -}}