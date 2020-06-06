# Kubernetes Toolkit

[![CircleCI](https://circleci.com/gh/swade1987/kubernetes-toolkit.svg?style=svg)](https://circleci.com/gh/swade1987/kubernetes-toolkit)

Minimal docker image for running useful Kubernetes tooling.

Images can be found at [https://eu.gcr.io/swade1987/kubernetes-toolkit](https://eu.gcr.io/swade1987/kubernetes-toolkit).

The container is also scanned by [https://github.com/aquasecurity/trivy](https://github.com/aquasecurity/trivy) as part of CI.

## Packages included

The docker container includes the following:

- kubectl (https://github.com/kubernetes/kubectl)
- kustomize (https://github.com/kubernetes-sigs/kustomize)
- Helm v2 (https://github.com/helm/helm)
- Helm v3 (https://github.com/helm/helm)
- kubeval (https://github.com/instrumenta/kubeval)
- conftest (https://github.com/instrumenta/conftest)
- kubeseal (utility from https://github.com/bitnami-labs/sealed-secrets)
- fluxctl (utility from https://github.com/fluxcd/flux)
- istioctl (https://github.com/istio/istio)
- yq (https://github.com/mikefarah/yq)
- jq (https://github.com/stedolan/jq)

## Rego Policies

The docker container also includes a number of Open Policy Agent Rego policies mainly around API deprecations.

The Kubernetes API deprecations can be found using https://relnotes.k8s.io/?markdown=deprecated

The policies can be executed from `/policies` inside the container.