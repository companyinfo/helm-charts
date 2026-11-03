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

## Gateway API

`helmet.app` includes `helmet.gateway` automatically. Routes default
to empty, so existing deployments are unchanged. You can also include
`{{ include "helmet.gateway" . }}` directly when composing individual templates.

Helmet manages application Routes. Infrastructure configuration owns GatewayClass, Gateway,
ListenerSet, and ReferenceGrant resources; Helmet does not create them.

Install the [Gateway API CRDs](https://gateway-api.sigs.k8s.io/guides/) and a
compatible Gateway controller separately. Helmet creates resources, not the CRDs
or controller. Each resource's features must be supported by your controller.
The default API version is `gateway.networking.k8s.io/v1`. `HTTPRoute`, `GRPCRoute`
and `TLSRoute` are served at `v1` from Gateway API 1.5; `TCPRoute` and `UDPRoute`
only from 1.6. For older installations, set `apiVersion` on each entry to a version
served by your CRDs, for example `gateway.networking.k8s.io/v1alpha2` for older
TCPRoute/UDPRoute/TLSRoute.

To attach your application to an existing shared Gateway:

```yaml
route:
  main:
    enabled: true # Optional; defaults to true.
    kind: HTTPRoute
    parentRefs:
      - name: shared-gateway
        namespace: infrastructure
        sectionName: https
    hostnames:
      - app.example.com
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
        backendRefs:
          - identifier: app
            port: http
```

`route` is a map keyed by a meaningful identifier such as `main`, `api`, or
`redirect`. Each entry supports `enabled`, which defaults to `true` when omitted.
Set `enabled: false` to omit that Route's Kubernetes resource. This applies to all
supported Route kinds, independently of other entries. For example, keep `main`
enabled while disabling a configured redirect in an environment override:

```yaml
route:
  main:
    enabled: true
  redirect:
    enabled: false
```

This override assumes the full route definitions are supplied by your base values.
Setting a previously deployed Route to `enabled: false` removes it from the Helm
release on upgrade. Companion resources in `extraObjects` are configured separately;
disabling a Route does not disable its policies or filters automatically.

The default kind is `HTTPRoute`; supported kinds are `HTTPRoute`, `GRPCRoute`,
`TLSRoute`, `TCPRoute`, and `UDPRoute`.

Resource names default to `<application-fullname>-<route-key>`. The route key is
truncated so the result stays within 63 characters, keeping the application prefix
intact; keys must be non-empty. Set `name` to override this and avoid truncation.
Entries also accept `namespace` (defaults to Helmet's namespace), `apiVersion`,
`labels`, and `annotations`. All remaining fields become the native Route spec,
including `parentRefs`, `hostnames`, and `rules`. Route values support templates
evaluated in the consuming chart's context. Resource metadata merges with
`commonLabels` and `commonAnnotations`, with resource values taking precedence.
Keep route keys and names stable across upgrades.

### Application Service references

Helmet creates one application Service, identified by `app`. In
`rules[].backendRefs`, use `identifier: app` to resolve its generated name and
Service port. `port` accepts a name from `service.ports`, a numeric Service port,
or a template resolving to either. If the Service has one port, `port` can be
omitted; with multiple ports it is required. This uses Service ports rather than
container ports or `targetPort`.

For example, `identifier: app` with `port: http` renders as:

```yaml
backendRefs:
  - name: my-release-my-app
    port: 80
```

The identifier cannot be combined with a backend name, namespace, non-Service
kind, or non-core group. Missing Services, unknown identifiers, and unknown ports
produce rendering errors. If the Route is deployed in another namespace, Helmet
sets the backend namespace to the application's Service namespace. The Service
owner must provision any required ReferenceGrant separately.

Explicit native backend references remain available:

```yaml
backendRefs:
  - identifier: app
    port: http
    weight: 90
  - name: canary
    port: 8080
    weight: 10
```

Explicit references use numeric Service ports and can include native `group`,
`kind`, `namespace`, and filters. The `identifier` shorthand applies only to
`rules[].backendRefs`; other references, such as request-mirror backends, use
native Kubernetes syntax. There is no implicit backend or rule: configure
`backendRefs` explicitly, or use filters for a redirect-only rule. Native fields
support path/header/method matches, traffic weights, redirects, rewrites, and
controller-supported timeouts.

See [the HTTPRoute example](examples/gateway/values.yaml) for an application
using a shared Gateway. The infrastructure manages the Gateway's HTTPS listener and
certificate. TLS settings on `ingress` apply only to Ingress.

For cross-namespace Route attachment, the Gateway listener's `allowedRoutes` must
permit the Route namespace. Cross-namespace backend or certificate references
require a ReferenceGrant in the **target** namespace, managed by that resource's
owner outside Helmet. A client application must not grant itself access to another
application's resources. Attaching a Route to a Gateway in another namespace uses
`allowedRoutes`, not a ReferenceGrant.

Ingress and Routes can coexist during migration; enable them independently.

## Extra objects and controller extensions

`extraObjects` renders additional Kubernetes manifests without coupling Helmet
to a controller or CRD schema. It accepts a list or map of complete objects or
YAML strings; map keys only identify entries and are not added to the manifests.
All entries are evaluated as Helm templates in the consuming application's context.
`helmet.app` includes them automatically, or you can include
`{{ include "helmet.extraObjects" . }}` directly.

For example, with NGINX Gateway Fabric and its RateLimitPolicy CRD installed,
attach a local rate limit to `route.main`:

```yaml
extraObjects:
  - apiVersion: gateway.nginx.org/v1alpha1
    kind: RateLimitPolicy
    metadata:
      name: '{{ include "common.names.fullname" . }}-rate-limit'
      namespace: '{{ include "common.names.namespace" . }}'
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: '{{ include "common.names.fullname" . }}-main'
      rateLimit:
        local:
          rules:
            - key: $binary_remote_addr
              zoneSize: 10m
              rate: 10r/s
```

Match `targetRefs[].name` and the policy namespace to your Route, including any
explicit name or namespace overrides. This example assumes the default generated
name is shorter than 63 characters; otherwise use the Route's truncated name or an
explicit Route name. These settings are interpreted by NGINX Gateway Fabric, not
by Helmet. Other controllers can use their own policy resources through the same
`extraObjects` field. See the
[NGINX RateLimitPolicy documentation](https://docs.nginx.com/nginx-gateway-fabric/traffic-management/rate-limit/)
for version requirements and behavior.

For filter-based extensions, supply the companion custom resource through
`extraObjects` and reference its name from the Route's native filter:

```yaml
# Within route.main.rules[]:
filters:
  - type: ExtensionRef
    extensionRef:
      group: gateway.nginx.org
      kind: SnippetsFilter
      name: app-cache
```

The example filter requires a separately defined `SnippetsFilter` named `app-cache`
in the Route namespace and snippet support enabled in the controller. Helmet passes
the filter through unchanged. Infrastructure configuration owns controller enablement,
shared cache storage and zones, and Gateway-wide policies.

Supply all required metadata yourself; Helmet does not inject names, namespaces,
common labels, or annotations into extra objects. The library does not install
CRDs or validate controller-specific specs. Extra objects are part of the Helm
release and follow its normal upgrade and uninstall lifecycle.

### More extra object examples

Choose the examples matching your installed controller. When combining examples,
put their entries in a single `extraObjects` list.

Envoy Gateway: local rate limit targeting route.main.

```yaml
extraObjects:
  - apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: BackendTrafficPolicy
    metadata:
      name: '{{ include "common.names.fullname" . }}-envoy-rate-limit'
      namespace: '{{ include "common.names.namespace" . }}'
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: '{{ include "common.names.fullname" . }}-main'
      rateLimit:
        local:
          rules:
            - limit:
                requests: 10
                unit: Second
```

Requires Envoy Gateway and its BackendTrafficPolicy CRD. This limit is local
to each Envoy instance, rather than a shared quota across replicas. As in the NGINX
example, match the target name and namespace to your Route overrides. See
[Envoy Gateway local rate limiting](https://gateway.envoyproxy.io/latest/tasks/traffic/local-rate-limit/).

Traefik: Middleware referenced by an HTTPRoute ExtensionRef filter.

```yaml
extraObjects:
  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: '{{ include "common.names.fullname" . }}-prefix'
      namespace: '{{ include "common.names.namespace" . }}'
    spec:
      addPrefix:
        prefix: /api
```

Creating a Middleware does not attach it automatically. Add this filter to the
application Route rule in the same namespace:

```yaml
# Add to the appropriate rule under route.main.rules:
filters:
  - type: ExtensionRef
    extensionRef:
      group: traefik.io
      kind: Middleware
      name: '{{ include "common.names.fullname" . }}-prefix'
```

Traefik must have both its Gateway and Kubernetes CRD providers enabled, with
the Middleware CRD installed. See
[Traefik Gateway API middleware filters](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/gateway-api/).

Standard Kubernetes ConfigMap supplied as a YAML string (no extra CRDs).

```yaml
extraObjects:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: '{{ include "common.names.fullname" . }}-settings'
      namespace: '{{ include "common.names.namespace" . }}'
    data:
      settings.yaml: |
        logLevel: info
        featureEnabled: true
```

This demonstrates a multiline YAML string and Helm template evaluation. Mount
or reference the ConfigMap explicitly in your application when needed; rendering
an extra object does not automatically wire it into the Deployment.

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
| `extraObjects`      | Additional Kubernetes manifests, evaluated as Helm templates.                                              | `[]`              |


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


### Gateway API parameters

| Name    | Description                                                                             | Value |
|---------|-----------------------------------------------------------------------------------------|-------|
| `route` | Named application routes; kind defaults to HTTPRoute and entries are enabled by default | `{}`  |


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
