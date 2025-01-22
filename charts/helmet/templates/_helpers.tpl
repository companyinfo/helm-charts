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
Render an array of env variables. The input can be a map or a slice.
Values can be templates using the "common.tplvalues.render" helper, but changes to scope are not processed.
Usage:
{{ include "helmet.toEnvArray" ( dict "envVars" .Values.envVars "context" $ ) }}
*/}}
{{- define "helmet.toEnvArray" -}}
{{- if kindIs "map" .envVars }}
{{- range $key, $val := .envVars }}
- name: {{ $key | quote }}
{{- if kindIs "string" $val }}
  value: {{ (include "common.tplvalues.render" (dict "value" $val "context" $.context)) | quote }}
{{- else if kindIs "map" $val }}
{{ include "common.tplvalues.render" (dict "value" (omit $val "name") "context" $.context) | indent 2 }}
{{- end -}}
{{- end -}}
{{- else if kindIs "slice" .envVars }}
{{ include "common.tplvalues.render" (dict "value" .envVars "context" $.context) }}
{{- end }}
{{- end -}}
