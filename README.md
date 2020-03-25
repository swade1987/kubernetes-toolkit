# Kubernetes Toolkit

[![Docker Repository on Quay](https://quay.io/repository/swade1987/kubernetes-toolkit/status "Docker Repository on Quay")](https://quay.io/repository/swade1987/kubernetes-toolkit)

Minimal docker image for running useful Kubernetes tooling.

The docker container includes the following:

- kubectl (https://github.com/kubernetes/kubectl)
- kustomize (https://github.com/kubernetes-sigs/kustomize)
- Helm v2 (https://github.com/helm/helm)
- Helm v3 (https://github.com/helm/helm)
- kubeval (https://github.com/instrumenta/kubeval)
- conftest (https://github.com/instrumenta/conftest)
- kubeseal (utility from https://github.com/bitnami-labs/sealed-secrets)

The docker container also includes a number of Open Policy Agent rego policies mainly around API deprecations.

The Kubernetes API deprecations can be found using https://relnotes.k8s.io/?markdown=deprecated