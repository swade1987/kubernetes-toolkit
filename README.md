# Kubernetes Toolkit 🛠️

[![release](https://github.com/swade1987/kubernetes-toolkit/actions/workflows/release.yml/badge.svg)](https://github.com/swade1987/kubernetes-toolkit/actions/workflows/release.yml)
[![image](https://github.com/swade1987/kubernetes-toolkit/actions/workflows/image.yml/badge.svg)](https://github.com/swade1987/kubernetes-toolkit/actions/workflows/image.yml)

This container provides a comprehensive suite of tools for Kubernetes. It is designed to be used in CI/CD pipelines and local development environments.

Images can be found at [https://eu.gcr.io/swade1987/kubernetes-toolkit](https://eu.gcr.io/swade1987/kubernetes-toolkit).

## Included Tools/Schemas

### Core Kubernetes Tools
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) (version passed as build argument)
- [kustomize](https://github.com/kubernetes-sigs/kustomize) (v5.4.3)
- [Helm v3](https://github.com/helm/helm) (v3.16.1)
- [helm-docs](https://github.com/norwoodj/helm-docs)  (v1.14.2)

### Validation & Testing
- [kubeconform](https://github.com/yannh/kubeconform) (v0.6.7)
- [conftest](https://github.com/open-policy-agent/conftest) (v0.55.0)
- [pluto](https://github.com/FairwindsOps/pluto) (v5.20.3)

### GitOps & Service Mesh
- [flux](https://github.com/fluxcd/flux2) (v2.3.0)
- [istioctl](https://github.com/istio/istio) (v1.23.1)

### Configuration Processing
- [yq](https://github.com/mikefarah/yq) (v4.44.3)
- [jq](https://github.com/stedolan/jq) (v1.7.1)

### Development & Linting Tools
- [shellcheck](https://github.com/koalaman/shellcheck) (v0.10.0)
- [jsonlint](https://github.com/zaach/jsonlint) (v1.6.3)

### Additional Components
- Python 3 with development tools
- Node.js and npm
- Required build dependencies (gcc, libxslt-dev, libxml2-dev, etc.)

### Schema Support
- Kubernetes JSON schemas (version matches kubectl client version)
- Flux CRD schemas (matching installed Flux version)

## Notes
- All binaries are installed in `/usr/local/bin/`
- Kubernetes schemas are stored in `/tmp/kubernetes-schemas/`
- Flux schemas are stored in `/tmp/flux-schemas/`

## Features

- Linting (via CI) using [kubeconform](https://github.com/yannh/kubeconform), [pluto](https://github.com/FairwindsOps/pluto) and [istioctl](https://istio.io/latest/docs/reference/commands/istioctl/).
    - Automated with GitHub Actions
- Commits must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Automated with GitHub Actions ([commit-lint](https://github.com/conventional-changelog/commitlint/#what-is-commitlint))
- Pull Request titles must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Automated with GitHub Actions ([pr-lint](https://github.com/amannn/action-semantic-pull-request))
- Commits must be signed with [Developer Certificate of Origin (DCO)](https://developercertificate.org/)
    - Automated with GitHub App ([DCO](https://github.com/apps/dco))
- Automatic [Semantic Releases](https://semantic-release.gitbook.io/)

## Getting started

Before working with the repository it is **mandatory** to execute the following command:

```
make initialise
```

The above command will install the `pre-commit` package and setup pre-commit checks for this repository including [conventional-pre-commit](https://github.com/compilerla/conventional-pre-commit) to make sure your commits match the conventional commit convention.

## Contributing to the repository

To contribute, please read the [contribution guidelines](CONTRIBUTING.md). You may also [report an issue](https://github.com/swade1987/kubernetes-toolkit/issues/new/choose).
