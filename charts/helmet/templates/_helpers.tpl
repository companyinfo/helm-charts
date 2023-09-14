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
{{- /* create an empty array */}}
{{- $array := list }}
{{- /* iterate over the given object */}}
{{- range $k, $v := . }}
{{- /* convert key and value into a dictionary: {name: FOO, value: bar} */}}
{{- $element := dict "name" $k "value" $v }}
{{- /* append the dictionary to the array */}}
{{- $array = append $array $element }}
{{- end }}
{{- /* print the array */}}
{{- $array | toYaml }}
{{- end }}