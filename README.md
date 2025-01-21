# Kubernetes Toolkit 🛠️

[![ci](https://github.com/swade1987/kubernetes-toolkit/actions/workflows/main.yaml/badge.svg)](https://github.com/swade1987/kubernetes-toolkit/actions/workflows/ci.yaml)

Minimal docker image for running useful Kubernetes tooling.

Images can be found at [https://eu.gcr.io/swade1987/kubernetes-toolkit](https://eu.gcr.io/swade1987/kubernetes-toolkit).

## Packages included

The docker container includes the following:

- conftest (https://github.com/instrumenta/conftest)
- flux (utility from https://github.com/fluxcd/flux)
- Helm v2 (https://github.com/helm/helm)
- Helm v3 (https://github.com/helm/helm)
- istioctl (https://github.com/istio/istio)
- jq (https://github.com/stedolan/jq)
- kubectl (https://github.com/kubernetes/kubectl)
- kubeseal (utility from https://github.com/bitnami-labs/sealed-secrets)
- kubeval (https://github.com/instrumenta/kubeval)
- kustomize (https://github.com/kubernetes-sigs/kustomize)
- yq (https://github.com/mikefarah/yq)

## Features

- Linting (via CI) using [kubeconform](https://github.com/yannh/kubeconform), [pluto](https://github.com/FairwindsOps/pluto) and [istioctl](https://istio.io/latest/docs/reference/commands/istioctl/).
    - Automated with GitHub Actions
- Commits must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Automated with GitHub Actions ([commit-lint](https://github.com/conventional-changelog/commitlint/#what-is-commitlint))
- Pull Request titles must meet [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
    - Automated with GitHub Actions ([pr-lint](https://github.com/amannn/action-semantic-pull-request))
- Commits must be signed with [Developer Certificate of Origin (DCO)](https://developercertificate.org/)
    - Automated with GitHub App ([DCO](https://github.com/apps/dco))

## Getting started

Before working with the repository it is **mandatory** to execute the following command:

```
make initialise
```

The above command will install the `pre-commit` package and setup pre-commit checks for this repository including [conventional-pre-commit](https://github.com/compilerla/conventional-pre-commit) to make sure your commits match the conventional commit convention.

## Contributing to the repository

To contribute, please read the [contribution guidelines](CONTRIBUTING.md). You may also [report an issue](https://github.com/swade1987/kubernetes-toolkit/issues/new/choose).
