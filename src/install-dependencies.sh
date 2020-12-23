#!/usr/bin/env bash

set -uo errexit

KUBECTL=$1
echo "downloading kubectl ${KUBECTL}"
curl -sL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL}/bin/linux/amd64/kubectl \
-o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
kubectl version --client

KUSTOMIZE=3.8.4
printf "\ndownloading kustomize ${KUSTOMIZE}\n"
curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize
kustomize version

HELM_V3=3.1.2
printf "\ndownloading helm ${HELM_V3}\n"
curl -sSL https://get.helm.sh/helm-v${HELM_V3}-linux-amd64.tar.gz | \
tar xz && mv linux-amd64/helm /usr/local/bin/helmv3 && rm -rf linux-amd64 && ln -s /usr/local/bin/helmv3 /usr/local/bin/helm
helmv3 version
helm version

KUBEVAL=0.15.0
printf "\ndownloading kubeval ${KUBEVAL}\n"
curl -sL https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL}/kubeval-linux-amd64.tar.gz | \
tar xz && mv kubeval /usr/local/bin/kubeval
kubeval --version

CONFTEST=0.18.2
printf "\ndownloading conftest ${CONFTEST}\n"
curl -sL https://github.com//open-policy-agent/conftest/releases/download/v${CONFTEST}/conftest_${CONFTEST}_Linux_x86_64.tar.gz | \
tar xz && mv conftest /usr/local/bin/conftest
conftest --version

KUBESEAL=v0.13.1
printf "\ndownloading kubeseal ${KUBESEAL}\n"
curl -sL https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL}/kubeseal-linux-amd64 \
-o /usr/local/bin/kubeseal && chmod +x /usr/local/bin/kubeseal
kubeseal --version

FLUXCTL=1.21.0
printf "\ndownloading fluxctl ${FLUXCTL}\n"
curl -sL https://github.com/fluxcd/flux/releases/download/${FLUXCTL}/fluxctl_linux_amd64 \
-o /usr/local/bin/fluxctl && chmod +x /usr/local/bin/fluxctl
fluxctl version

ISTIOCTL=1.7.6
printf "\ndownloading istioctl ${ISTIOCTL}\n"
curl -sL https://github.com/istio/istio/releases/download/${ISTIOCTL}/istio-${ISTIOCTL}-linux-amd64.tar.gz | \
tar xz && mv istio-${ISTIOCTL}/bin/istioctl /usr/local/bin/istioctl
rm -rf istio-${ISTIOCTL}
istioctl version --remote=false

YQ=3.2.1
printf "\ndownloading yq\n"
curl -sL https://github.com/mikefarah/yq/releases/download/${YQ}/yq_linux_amd64 \
-o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
yq --version

JQ=1.6
printf "\ndownloading jq\n"
curl -sL https://github.com/stedolan/jq/releases/download/jq-${JQ}/jq-linux64 \
-o /usr/local/bin/jq && chmod +x /usr/local/bin/jq
jq --version

printf "\nfetch kubeval kubernetes json schemas for v1.$(kubectl version --client=true --short=true | awk '{print $3}' | awk -F'.' '{print $2}').0\n"
mkdir -p /usr/local/kubeval/schemas && \
curl https://codeload.github.com/instrumenta/kubernetes-json-schema/tar.gz/master | \
tar -C /usr/local/kubeval/schemas --strip-components=1 -xzf - \
kubernetes-json-schema-master/v1.$(kubectl version --client=true --short=true | awk '{print $3}' | awk -F'.' '{print $2}').0-standalone-strict