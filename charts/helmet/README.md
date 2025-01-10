# Helmet

The Helmet is a [Helm Library Chart](https://helm.sh/docs/topics/library_charts/) that defines many chart templates like Deployment, Service, Ingress, etc which can used in other application charts.

## Background

In Helm 3, their team introduced the concept of a
[Library chart](https://helm.sh/docs/topics/library_charts/).

> A library chart is a type of Helm chart that defines chart primitives or
definitions which can be shared by Helm templates in other charts. This
allows users to share snippets of code that can be re-used across charts,
avoiding repetition and keeping charts DRY.

The Helmet library was created because we saw many charts requiring only a
few select configuration options in their Helm charts.

In order to stay somewhat DRY (Don't Repeat Yourself) and keeping with Helm 3
usage for a Library chart, we saw this pattern and decided it was worth it for
us to create a library. This means each one of application charts has a
dependency on what we call the `Helmet` library.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.9.0+

## Getting started
1. Add the Helmet as a dependency to your chart.
```yaml
# file: Chart.yaml

dependencies:
  - name: helmet
    version: 0.12.0
    repository: https://charts.companyinfo.dev
    import-values: # <== It is mandatory if you want to import the Helmet default values.
      - defaults
```

2. Update the Helm dependencies:
```shell
$ helm dependency update
```

3. Include the app template:
```yaml
# file: templates/app.yaml

{{ include "helmet.app" . }}
```

4. Configure your chart
```yaml
# file: values.yaml

image:
  repository: nginx

ports:
  - name: http
    containerPort: 80
    protocol: TCP

ingress:
  enabled: true
```

5. Install the chart:
```shell
$ helm install nginx .
```

## Parameters

### Global parameters

| Name                      | Description                                     | Value |
|---------------------------|-------------------------------------------------|-------|
| `global.imageRegistry`    | Global Docker image registry                    | `""`  |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]`  |
| `global.storageClass`     | Global StorageClass for Persistent Volume(s)    | `""`  |


### Common parameters

| Name                | Description                                                                                                | Value             |
|---------------------|------------------------------------------------------------------------------------------------------------|-------------------|
| `kubeVersion`       | Force target Kubernetes version (using Helm capabilities if not set)                                       | `""`              |
| `nameOverride`      | String to partially override common.names.fullname template with a string (will maintain the release name) | `""`              |
| `fullnameOverride`  | String to fully override common.names.fullname template with a string                                      | `""`              |
| `namespaceOverride` | String to fully override common.names.namespace template with a string                                     | `""`              |
| `clusterDomain`     | Kubernetes Cluster Domain name                                                                             | `"cluster.local"` |
| `commonLabels`      | Labels to be added to all deployed resources                                                               | `{}`              |
| `commonAnnotations` | Annotations to be added to all deployed resources                                                          | `{}`              |


### Image parameters

| Name                | Description                                                                                                  | Value       |
|---------------------|--------------------------------------------------------------------------------------------------------------|-------------|
| `image.registry`    | Image registry                                                                                               | `docker.io` |
| `image.repository`  | Image repository                                                                                             | `""`        |
| `image.tag`         | Image tag (immutable tags are recommended)                                                                   | `latest`    |
| `image.digest`      | Image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag              | `""`        |
| `image.pullPolicy`  | Image pull policy, Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent'                 | `Always`    |
| `image.pullSecrets` | Image pull secrets, specify an array of imagePullSecrets (secrets must be manually created in the namespace) | `[]`        |


### Deployment/Statefulset parameters

| Name                                    | Description                                                                                                              | Value                                                            |
|-----------------------------------------|--------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| `replicaCount`                          | Number of APP replicas                                                                                                   | `1`                                                              |
| `revisionHistoryLimit`                  | The number of old history to retain to allow rollback                                                                    | `10`                                                             |
| `ports`                                 | List of ports to expose from the container                                                                               | `[{"name": "http", "containerPort": "8080", "protocol": "TCP"}]` |
| `livenessProbe.enabled`                 | Enable livenessProbe on APP container (only main container)                                                              | `false`                                                          |
| `readinessProbe.enabled`                | Enable readinessProbe on APP container (only main container)                                                             | `false`                                                          |
| `startupProbe.enabled`                  | Enable startupProbe on APP container (only main container)                                                               | `false`                                                          |
| `podRestartPolicy`                      | Set restart policy for all containers within the pod                                                                     | `Always`                                                         |
| `podSecurityContext.enabled`            | Enabled APP pods' Security Context                                                                                       | `false`                                                          |
| `podSecurityContext.fsGroup`            | Set APP pod's Security Context fsGroup                                                                                   | `0`                                                              |
| `containerSecurityContext.enabled`      | Enabled APP containers' Security Context (only main container)                                                           | `false`                                                          |
| `containerSecurityContext.runAsUser`    | Set APP containers' Security Context runAsUser                                                                           | `1001`                                                           |
| `containerSecurityContext.runAsNonRoot` | Set APP containers' Security Context runAsNonRoot                                                                        | `true`                                                           |
| `lifecycleHooks`                        | for the APP main container to automate configuration before or after startup                                             | `{}`                                                             |
| `resources.limits`                      | The resources limits for the APP container (only main container)                                                         | `{}`                                                             |
| `resources.requests`                    | The resources requests for the APP container (only main container)                                                       | `{}`                                                             |
| `hostAliases`                           | Add deployment host aliases                                                                                              | `[]`                                                             |
| `podLabels`                             | Additional pods' labels                                                                                                  | `{}`                                                             |
| `podAnnotations`                        | Additional pods' annotations                                                                                             | `{}`                                                             |
| `podAffinityPreset`                     | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                      | `""`                                                             |
| `podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                 | `soft`                                                           |
| `nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                | `""`                                                             |
| `nodeAffinityPreset.key`                | Node label key to match Ignored if `affinity` is set.                                                                    | `""`                                                             |
| `nodeAffinityPreset.values`             | Node label values to match. Ignored if `affinity` is set.                                                                | `[]`                                                             |
| `affinity`                              | Affinity for pod assignment                                                                                              | `{}`                                                             |
| `nodeSelector`                          | Node labels for pod assignment                                                                                           | `{}`                                                             |
| `tolerations`                           | Tolerations for pod assignment                                                                                           | `[]`                                                             |
| `topologySpreadConstraints`             | Topology Spread Constraints for pod assignment spread across your cluster among failure-domains. Evaluated as a template | `{}`                                                             |
| `priorityClassName`                     | Name of the existing priority class to be used by APP pods, priority class needs to be created beforehand                | `""`                                                             |
| `schedulerName`                         | Use an alternate scheduler, e.g. "stork"                                                                                 | `""`                                                             |
| `terminationGracePeriodSeconds`         | Seconds APP pod needs to terminate gracefully                                                                            | `""`                                                             |
| `updateStrategy.type`                   | APP deployment strategy type                                                                                             | `RollingUpdate`                                                  |
| `updateStrategy.rollingUpdate`          | APP deployment rolling update configuration parameters                                                                   | `{}`                                                             |
| `extraVolumes`                          | Optionally specify extra list of additional volumes for the APP pod(s)                                                   | `[]`                                                             |
| `extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts for the APP container(s)                                        | `[]`                                                             |
| `sidecars`                              | Add additional sidecar containers to the APP pod(s)                                                                      | `[]`                                                             |
| `initContainers`                        | Add additional init containers to the APP pod(s)                                                                         | `[]`                                                             |
| `command`                               | Override main container's command                                                                                        | `[]`                                                             |
| `args`                                  | Override main container's args                                                                                           | `[]`                                                             |
| `envVars`                               | Environment variables to be set on APP container                                                                         | `{} or []`                                                             |
| `envVarsConfigMap`                      | ConfigMap with environment variables                                                                                     | `""`                                                             |
| `envVarsSecret`                         | Secret with environment variables                                                                                        | `""`                                                             |


### Autoscaling parameters

| Name                       | Description                                                                                        | Value   |
|----------------------------|----------------------------------------------------------------------------------------------------|---------|
| `autoscaling.enabled`      | Enable APP deployment autoscaling (Deploy a HorizontalPodAutoscaler object for the APP deployment) | `false` |
| `autoscaling.minReplicas`  | Minimum number of replicas to scale back                                                           | `3`     |
| `autoscaling.maxReplicas`  | Maximum number of replicas to scale out                                                            | `5`     |
| `autoscaling.targetCPU`    | Define the CPU target to trigger the scaling actions (utilization percentage)                      | `80`    |
| `autoscaling.targetMemory` | Define the memory target to trigger the scaling actions (utilization percentage)                   | `80`    |
| `autoscaling.metrics`      | Metrics to use when deciding to scale the deployment (evaluated as a template)                     | `[]`    |


### ConfigMap parameters

| Name                    | Description                                     | Value         |
|-------------------------|-------------------------------------------------|---------------|
| `configMap.mounted`     | Mount the ConfigMap in the main container       | `false`       |
| `configMap.mountPath`   | ConfigMap mount path                            | `/app/config` |
| `configMap.subPath`     | ConfigMap sub path                              | `""`          |
| `configMap.data`        | ConfigMap data                                  | `{}`          |
| `configMap.annotations` | Additional custom annotations for the ConfigMap | `{}`          |
| `configMap.labels`      | Additional custom labels for the ConfigMap      | `{}`          |


### Secret parameters

| Name                 | Description                                                             | Value    |
|----------------------|-------------------------------------------------------------------------|----------|
| `secret.type`        | The type is used to facilitate programmatic handling of the Secret data | `Opaque` |
| `secret.data`        | Store data in key-value pairs (base64 encoded)                          | `{}`     |
| `secret.stringData`  | Store data in key-value pairs                                           | `{}`     |
| `secret.annotations` | Additional custom annotations for the Secret                            | `{}`     |
| `secret.labels`      | Additional custom labels for the Secret                                 | `{}`     |


### Traffic Exposure (Ingress) parameters

| Name                       | Description                                                                                   | Value                    |
|----------------------------|-----------------------------------------------------------------------------------------------|--------------------------|
| `ingress.enabled`          | Enable ingress resource for the APP                                                           | `false`                  |
| `ingress.path`             | Path for the default host                                                                     | `/`                      |
| `ingress.apiVersion`       | Override API Version (automatically detected if not set)                                      | `""`                     |
| `ingress.pathType`         | Ingress path type                                                                             | `ImplementationSpecific` |
| `ingress.hostname`         | Default host for the ingress resource, a host pointing to this will be created                | `app.local`              |
| `ingress.annotations`      | Additional annotations for the Ingress resource                                               | `{}`                     |
| `ingress.ingressClassName` | Set the ingerssClassName on the ingress record for k8s 1.18+                                  | `""`                     |
| `ingress.tls`              | Enable TLS configuration for the hostname defined at ingress.hostname parameter               | `false`                  |
| `ingress.extraHosts`       | An array with additional hostname(s) to be covered with the ingress record                    | `[]`                     |
| `ingress.extraPaths`       | Any additional arbitrary paths that may need to be added to the ingress under the main host   | `[]`                     |
| `ingress.selfSigned`       | Create a TLS secret for this ingress record using self-signed certificates generated by Helm  | `false`                  |
| `ingress.extraTls`         | TLS configuration for additional hostname(s) to be covered with this ingress record           | `[]`                     |
| `ingress.secrets`          | If you're providing your own certificates, please use this to add the certificates as secrets | `[]`                     |
| `ingress.existingSecret`   | It is you own the certificate as secret                                                       | `""`                     |
| `ingress.extraRules`       | Additional rules to be covered with this ingress record                                       | `[]`                     |


### Traffic Exposure (Service) parameters

| Name                               | Description                                                      | Value                                                                     |
|------------------------------------|------------------------------------------------------------------|---------------------------------------------------------------------------|
| `service.type`                     | APP service type                                                 | `ClusterIP`                                                               |
| `service.ports`                    | APP service ports                                                | `[{"name": "http", "protocol": "TCP", "port": 80, "targetPort": "http"}]` |
| `service.sessionAffinity`          | Control where client requests go, to the same pod or round-robin | `None`                                                                    |
| `service.clusterIP`                | APP service Cluster IP                                           | `""`                                                                      |
| `service.loadBalancerIP`           | APP service Load Balancer IP                                     | `""`                                                                      |
| `service.loadBalancerSourceRanges` | APP service Load Balancer sources                                | `[]`                                                                      |
| `service.externalTrafficPolicy`    | APP service external traffic policy                              | `Cluster`                                                                 |
| `service.annotations`              | Additional custom annotations for APP service                    | `{}`                                                                      |


### Prometheus Operator ServiceMonitor parameters

| Name                               | Description                                                                                     | Value     |
|------------------------------------|-------------------------------------------------------------------------------------------------|-----------|
| `serviceMonitor.enabled`           | Specify if a ServiceMonitor will be deployed for Prometheus Operator                            | `false`   |
| `serviceMonitor.namespace`         | Namespace in which Prometheus is running                                                        | `""`      |
| `serviceMonitor.labels`            | Additional ServiceMonitor labels (evaluated as a template)                                      | `{}`      |
| `serviceMonitor.annotations`       | Additional ServiceMonitor annotations (evaluated as a template)                                 | `{}`      |
| `serviceMonitor.jobLabel`          | The name of the label on the target service to use as the job name in Prometheus                | `""`      |
| `serviceMonitor.honorLabels`       | The honorLabels chooses the metric's labels on collisions with target labels                    | `false`   |
| `serviceMonitor.interval`          | How frequently to scrape metrics                                                                | `""`      |
| `serviceMonitor.scrapeTimeout`     | Timeout after which the scrape is ended                                                         | `""`      |
| `serviceMonitor.metricRelabelings` | Specify additional relabeling of metrics                                                        | `[]`      |
| `serviceMonitor.relabelings`       | Specify general relabeling                                                                      | `[]`      |
| `serviceMonitor.selector`          | Prometheus instance selector labels                                                             | `{}`      |
| `serviceMonitor.namespaceSelector` | The namespaceSelector is a selector for selecting either all namespaces or a list of namespaces | `{}`      |
| `serviceMonitor.port`              | The port used by ServiceMonitor                                                                 | `http`    |
| `serviceMonitor.path`              | The path used by ServiceMonitor                                                                 | `metrics` |

### Prometheus Operator PodMonitor parameters

| Name                               | Description                                                                                     | Value     |
|------------------------------------|-------------------------------------------------------------------------------------------------|-----------|
| `podMonitor.enabled`           | Specify if a PodMonitor will be deployed for Prometheus Operator                                     | `false`   |
| `podMonitor.namespace`         | Namespace in which Prometheus is running                                                             | `""`      |
| `podMonitor.labels`            | Additional PodMonitor labels (evaluated as a template)                                               | `{}`      |
| `podMonitor.annotations`       | Additional PodMonitor annotations (evaluated as a template)                                          | `{}`      |
| `podMonitor.jobLabel`          | The name of the label on the target service to use as the job name in Prometheus                     | `""`      |
| `podMonitor.honorLabels`       | The honorLabels chooses the metric's labels on collisions with target labels                         | `false`   |
| `podMonitor.interval`          | How frequently to scrape metrics                                                                     | `""`      |
| `podMonitor.scrapeTimeout`     | Timeout after which the scrape is ended                                                              | `""`      |
| `podMonitor.metricRelabelings` | Specify additional relabeling of metrics                                                             | `[]`      |
| `podMonitor.relabelings`       | Specify general relabeling                                                                           | `[]`      |
| `podMonitor.selector`          | Prometheus instance selector labels                                                                  | `{}`      |
| `podMonitor.namespaceSelector` | The namespaceSelector is a selector for selecting either all namespaces or a list of namespaces      | `{}`      |
| `podMonitor.port`              | The port used by PodMonitor                                                                          | `http`    |
| `podMonitor.path`              | The path used by PodMonitor                                                                          | `metrics` |

### ServiceAccount parameters

| Name                                          | Description                                                            | Value   |
|-----------------------------------------------|------------------------------------------------------------------------|---------|
| `serviceAccount.create`                       | Enable creation of ServiceAccount for APP pods                         | `false` |
| `serviceAccount.name`                         | The name of the ServiceAccount to use                                  | `""`    |
| `serviceAccount.automountServiceAccountToken` | Allows auto mount of ServiceAccountToken on the serviceAccount created | `true`  |
| `serviceAccount.annotations`                  | Additional custom annotations for the ServiceAccount                   | `{}`    |
| `serviceAccount.labels`                       | Additional custom labels for the ServiceAccount                        | `{}`    |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
$ helm install my-release --set ingress.hostname=example.com,serviceMonitor.enabled=true company/app
```

The above command sets the APP Ingress hostname to `example.com` and enabled the ServiceMonitor.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install my-release -f values.yaml company/app
```

> **Tip**: You can use the default [values.yaml](values.yaml) just by [`import-values`](#Getting started)

## Configuration and installation details

It is strongly recommended to use immutable tags in a production environment. This ensures your deployment does not change automatically if the same tag is updated with a different image.

### Ingress

This chart provides support for ingress resources. If you have an ingress controller installed on your cluster, such as nginx-ingress or traefik you can utilize the ingress controller to serve your application.
To enable ingress integration, please set `ingress.enabled` to `true`.

#### Hosts

Most likely you will only want to have one hostname that maps to this APP installation. If that's your case, the property `ingress.hostname` will set it. However, it is possible to have more than one host. To facilitate this, the `ingress.extraHosts` object can be specified as an array. You can also use `ingress.extraTLS` to add the TLS configuration for extra hosts.

For each host indicated at `ingress.extraHosts`, please indicate a `name`, `path`, and any `annotations` that you may want the ingress controller to know about.

For annotations, please see [this document](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.md). Not all annotations are supported by all ingress controllers, but this document does a good job of indicating which annotation is supported by many popular ingress controllers.

### TLS Secrets

This chart will facilitate the creation of TLS secrets for use with the ingress controller, however, this is not required.  There are three common use cases:

- Helm generates/manages certificate secrets
- User generates/manages certificates separately
- An additional tool (like cert-manager) manages the secrets for the application

In the first two cases, one will need a certificate and a key.  We would expect them to look like this:

- certificate files should look like (and there can be more than one certificate if there is a certificate chain)

```
-----BEGIN CERTIFICATE-----
MIID6TCCAtGgAwIBAgIJAIaCwivkeB5EMA0GCSqGSIb3DQEBCwUAMFYxCzAJBgNV
...
jScrvkiBO65F46KioCL9h5tDvomdU1aqpI/CBzhvZn1c0ZTf87tGQR8NK7v7
-----END CERTIFICATE-----
```

- keys should look like:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAvLYcyu8f3skuRyUgeeNpeDvYBCDcgq+LsWap6zbX5f8oLqp4
...
wrj2wDbCDCFmfqnSJ+dKI3vFLlEz44sAV8jX/kd4Y6ZTQhlLbYc=
-----END RSA PRIVATE KEY-----
```

If you are going to use Helm to manage the certificates, please copy these values into the `certificate` and `key` values for a given `ingress.secrets` entry.

If you are going to manage TLS secrets outside of Helm, please know that you can create a TLS secret (named `app.local-tls` for example).

Please see [this example](https://github.com/kubernetes/contrib/tree/master/ingress/controllers/nginx/examples/tls) for more information.

### Adding environment variables

In case you want to add extra environment variables (useful for advanced operations like custom init scripts), you can use the `envVars` property.

```yaml
envVars:
  - name: LOG_LEVEL
    value: error
```

Alternatively, you can use a ConfigMap or a Secret with the environment variables. To do so, use the `.envVarsConfigMap` or the `envVarsSecret` properties.

### Setting Pod's affinity

This chart allows you to set your custom affinity using the `affinity` parameter. Find more information about Pod's affinity in the [kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity).

As an alternative, you can use of the preset configurations for pod affinity, pod anti-affinity, and node affinity available at the [bitnami/common](https://github.com/bitnami/charts/tree/master/bitnami/common#affinities) chart. To do so, set the `podAffinityPreset`, `podAntiAffinityPreset`, or `nodeAffinityPreset` parameters.

### Sidecars and Init Containers

If you have a need for additional containers to run within the same pod as Redis&reg;, you can do so via the `sidecars` config parameter. Simply define your container according to the Kubernetes container spec.

```yaml
sidecars:
  - name: your-image-name
    image: your-image
    imagePullPolicy: Always
    ports:
      - name: portName
        containerPort: 1234
```

Similarly, you can add extra init containers using the `initContainers` parameter.

```yaml
initContainers:
  - name: your-image-name
    image: your-image
    imagePullPolicy: Always
    ports:
      - name: portName
        containerPort: 1234
```
