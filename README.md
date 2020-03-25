# Kubernetes Toolkit

[![CircleCI](https://circleci.com/gh/swade1987/kubernetes-toolkit.svg?style=svg)](https://circleci.com/gh/swade1987/kubernetes-toolkit)
[![Docker Repository on Quay](https://quay.io/repository/swade1987/kubernetes-toolkit/status "Docker Repository on Quay")](https://quay.io/repository/swade1987/kubernetes-toolkit)

Minimal docker image for running useful Kubernetes tooling.

## Packages included

The docker container includes the following:

- [kubectl](https://github.com/kubernetes/kubectl)
- [kustomize](https://github.com/kubernetes-sigs/kustomize)
- [Helm v2](https://github.com/helm/helm)
- [Helm v3](https://github.com/helm/helm)
- [kubeval](https://github.com/instrumenta/kubeval)
- [conftest](https://github.com/instrumenta/conftest)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets)

## Rego Policies

The docker container also includes a number of Open Policy Agent Rego policies mainly around API deprecations.
The Kubernetes API deprecations can be found using https://relnotes.k8s.io/?markdown=deprecated