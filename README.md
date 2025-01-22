# Company.info Helm Charts [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/companyinfo)](https://artifacthub.io/packages/search?repo=companyinfo)
Company.info Helm charts repository.

## TL;DR

```bash
$ helm repo add companyinfo https://charts.companyinfo.dev
$ helm search repo companyinfo
$ helm install my-release companyinfo/<chart>
```

## Before you begin

### Prerequisites

- Kubernetes 1.19+
- Helm 3.9.0+

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

### Add Repo

The following command allows you to download and install all the charts from this repository:

```bash
$ helm repo add companyinfo https://charts.companyinfo.dev
```

### Using Helm

Once you have installed the Helm client, you can deploy a Company.info Helm Chart into a Kubernetes cluster.

Please refer to the [Quick Start guide](https://helm.sh/docs/intro/quickstart/) if you wish to get running in just a few commands, otherwise the [Using Helm Guide](https://helm.sh/docs/intro/using_helm/) provides detailed instructions on how to use the Helm client to manage packages on your Kubernetes cluster.

Useful Helm Client Commands:
* View available charts: `helm search repo`
* Install a chart: `helm install my-release companyinfo/<package-name>`
* Upgrade your application: `helm upgrade`

## License

Copyright &copy; 2025 Company.info

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.