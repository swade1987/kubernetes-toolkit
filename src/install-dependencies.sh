#!/usr/bin/env bash

set -uo errexit

KUBERNETES_VERSION=$1
printf "Downloading kubectl %s\n" "${KUBERNETES_VERSION}"
curl -sL https://dl.k8s.io/release/v"${KUBERNETES_VERSION}"/bin/linux/amd64/kubectl \
-o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
kubectl version --client

KUSTOMIZE=5.6.0
printf "\nDownloading kustomize %s\n" "${KUSTOMIZE}"
curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize
kustomize version

HELM_V3=3.17.1
printf "\nDownloading helm %s\n" "${HELM_V3}"
curl -sSL https://get.helm.sh/helm-v${HELM_V3}-linux-amd64.tar.gz | \
tar xz && mv linux-amd64/helm /usr/local/bin/helmv3 && rm -rf linux-amd64 && ln -s /usr/local/bin/helmv3 /usr/local/bin/helm
helmv3 version
helm version

KUBECONFORM=0.6.7
printf "\nDownloading kubeconform %s\n" "${KUBECONFORM}"
curl -sL https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM}/kubeconform-linux-amd64.tar.gz | \
tar xz && mv kubeconform /usr/local/bin/kubeconform
kubeconform -v

CONFTEST=0.55.0
printf "\nDownloading conftest %s\n" "${CONFTEST}"
curl -sL https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST}/conftest_${CONFTEST}_Linux_x86_64.tar.gz | \
tar xz && mv conftest /usr/local/bin/conftest
conftest --version

FLUX=2.6.1
printf "\nDownloading flux %s\n" "${FLUX}"
curl -sL https://github.com/fluxcd/flux2/releases/download/v${FLUX}/flux_${FLUX}_linux_amd64.tar.gz | \
tar xz && mv flux /usr/local/bin/flux
rm -rf flux_${FLUX}
flux version --client

ISTIOCTL=1.26.1
# shellcheck disable=SC2059
printf "\nDownloading istioctl %s\n" "${ISTIOCTL}"
curl -sL https://github.com/istio/istio/releases/download/${ISTIOCTL}/istioctl-${ISTIOCTL}-linux-amd64.tar.gz | \
tar xz && mv istioctl /usr/local/bin/istioctl
rm -rf istio-${ISTIOCTL}
istioctl version --remote=false

YQ=v4.44.3
printf "\nDownloading yq %s\n" "${YQ}"
curl -sL https://github.com/mikefarah/yq/releases/download/${YQ}/yq_linux_amd64 \
-o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
yq --version

JQ=1.7.1
printf "\nDownloading jq %s\n" "${JQ}"
curl -sL https://github.com/stedolan/jq/releases/download/jq-${JQ}/jq-linux64 \
-o /usr/local/bin/jq && chmod +x /usr/local/bin/jq
jq --version

# Install Python 3 and additional libraries
apk add --update --no-cache python3 gcc libxslt-dev libxml2-dev libxml2 libxslt build-base python3-dev nodejs npm

HELM_DOCS=1.14.2
printf "\nDownloading helm-docs %s\n" "${HELM_DOCS}"
curl -sL https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOCS}/helm-docs_${HELM_DOCS}_Linux_x86_64.tar.gz | \
tar xz && mv helm-docs /usr/local/bin/helm-docs
rm -rf helm-docs_${HELM_DOCS}_Linux_x86_64
helm-docs --version

JSONLINT=1.6.3
printf "\nDownloading jsonlint %s\n" "${JSONLINT}"
npm install jsonlint@${JSONLINT} -g
jsonlint --version || :

PLUTO=5.20.3
printf "\nDownloading pluto %s\n" "${PLUTO}"
curl -sL https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO}/pluto_${PLUTO}_linux_amd64.tar.gz | \
tar xz && mv pluto /usr/local/bin/pluto
rm -rf pluto_${PLUTO}_linux_amd64.tar.gz
pluto version

SHELLCHECK=v0.10.0
printf "\ndownloading shellcheck %s \n" "${SHELLCHECK}"
wget https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK}/shellcheck-${SHELLCHECK}.linux.x86_64.tar.xz -O - | tar xJf -
mv shellcheck-${SHELLCHECK}/shellcheck /usr/local/bin/shellcheck && rm -rf shellcheck-${SHELLCHECK}
shellcheck --version

TRIVY=0.59.0
printf "\nDownloading trivy %s\n" "${TRIVY}"
curl -sL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY}/trivy_${TRIVY}_Linux-64bit.tar.gz | \
tar xz && mv trivy /usr/local/bin/trivy
rm -rf trivy_${TRIVY}_Linux-64bit.tar.gz
trivy version

printf "\nFetching kubernetes json schemas for v%s\n" "${KUBERNETES_VERSION}"
mkdir -p /tmp/kubernetes-schemas/v"${KUBERNETES_VERSION}"-standalone-strict && \
curl -sL "https://github.com/swade1987/k8s-schemas/releases/download/v${KUBERNETES_VERSION}/kubernetes-json-schema-v${KUBERNETES_VERSION}-standalone-strict.zip" > /tmp/schema.zip && \
unzip -o /tmp/schema.zip -d /tmp/kubernetes-schemas && \
rm /tmp/schema.zip

printf "\nFetching flux json schemas for v%s\n" "${FLUX}"
mkdir -p /tmp/flux-schemas/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/download/v${FLUX}/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-schemas/master-standalone-strict

FLUX_OPERATOR=0.21.0
printf "\nFetching flux operator json schemas for v%s\n" "${FLUX_OPERATOR}"
mkdir -p /tmp/flux-operator-schemas/master-standalone-strict
curl -sL https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${FLUX_OPERATOR}/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-operator-schemas/master-standalone-strict
