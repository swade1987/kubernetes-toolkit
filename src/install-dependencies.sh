#!/usr/bin/env bash

set -uo errexit

KUBECTL=$1
printf "Downloading kubectl %s\n" "${KUBECTL}"
curl -sL https://storage.googleapis.com/kubernetes-release/release/v"${KUBECTL}"/bin/linux/amd64/kubectl \
-o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
kubectl version --client

KUSTOMIZE=4.4.1
printf "\nDownloading kustomize %s\n" "${KUSTOMIZE}"
curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE}/kustomize_v${KUSTOMIZE}_linux_amd64.tar.gz | \
tar xz && mv kustomize /usr/local/bin/kustomize
kustomize version

HELM_V3=3.7.2
printf "\nDownloading helm %s\n" "${HELM_V3}"
curl -sSL https://get.helm.sh/helm-v${HELM_V3}-linux-amd64.tar.gz | \
tar xz && mv linux-amd64/helm /usr/local/bin/helmv3 && rm -rf linux-amd64 && ln -s /usr/local/bin/helmv3 /usr/local/bin/helm
helmv3 version
helm version

KUBEVAL=0.16.1
printf "\nDownloading kubeval %s\n" "${KUBEVAL}"
curl -sL https://github.com/instrumenta/kubeval/releases/download/v${KUBEVAL}/kubeval-linux-amd64.tar.gz | \
tar xz && mv kubeval /usr/local/bin/kubeval
kubeval --version

CONFTEST=0.30.0
printf "\nDownloading conftest %s\n" "${CONFTEST}"
curl -sL https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST}/conftest_${CONFTEST}_Linux_x86_64.tar.gz | \
tar xz && mv conftest /usr/local/bin/conftest
conftest --version

ISTIOCTL=1.12.0
# shellcheck disable=SC2059
printf "\nDownloading istioctl %s\n" "${ISTIOCTL}"
curl -sL https://github.com/istio/istio/releases/download/${ISTIOCTL}/istioctl-${ISTIOCTL}-linux-amd64.tar.gz | \
tar xz && mv istioctl /usr/local/bin/istioctl
rm -rf istio-${ISTIOCTL}
istioctl version --remote=false

YQ=v4.16.2
printf "\nDownloading yq %s\n" "${YQ}"
curl -sL https://github.com/mikefarah/yq/releases/download/${YQ}/yq_linux_amd64 \
-o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
yq --version

JQ=1.6
printf "\nDownloading jq %s\n" "${JQ}"
curl -sL https://github.com/stedolan/jq/releases/download/jq-${JQ}/jq-linux64 \
-o /usr/local/bin/jq && chmod +x /usr/local/bin/jq
jq --version

# Install Python 3 and additional libraries
apk add --update --no-cache python3 gcc libxslt-dev libxml2-dev libxml2 libxslt build-base python3-dev nodejs npm && \
if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
python3 -m ensurepip && \
rm -r /usr/lib/python*/ensurepip && \
pip3 install --no-cache --upgrade pip setuptools wheel && \
if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

AWSCLI=1.22.44
printf "\nDownloading awscli %s\n" "${AWSCLI}"
pip3 install --quiet --upgrade awscli==${AWSCLI}
aws --version

HELM_DOCS=1.7.0
printf "\nDownloading helm-docs %s\n" "${HELM_DOCS}"
curl -sL https://github.com/norwoodj/helm-docs/releases/download/v${HELM_DOCS}/helm-docs_${HELM_DOCS}_Linux_x86_64.tar.gz | \
tar xz && mv helm-docs /usr/local/bin/helm-docs
rm -rf helm-docs_${HELM_DOCS}_Linux_x86_64
helm-docs --version

PRE_COMMIT=v2.17.0
printf "\nDownloading pre-commit %s\n" "${PRE_COMMIT}"
pip3 install --quiet --upgrade pre-commit==${PRE_COMMIT}
pre-commit --version

node --version
npm --version

JSONLINT=1.6.3
printf "\nDownloading jsonlint %s\n" "${JSONLINT}"
npm install jsonlint@${JSONLINT} -g
jsonlint --version || :

PLUTO=5.0.0
printf "\nDownloading pluto %s\n" "${PLUTO}"
curl -sL https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO}/pluto_${PLUTO}_linux_amd64.tar.gz | \
tar xz && mv pluto /usr/local/bin/pluto
rm -rf pluto_5.0.0_linux_amd64.tar.gz
pluto version

SHELLCHECK=v0.7.2
printf "\ndownloading shellcheck %s \n" "${SHELLCHECK}"
wget https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK}/shellcheck-${SHELLCHECK}.linux.x86_64.tar.xz -O - | tar xJf -
mv shellcheck-${SHELLCHECK}/shellcheck /usr/local/bin/shellcheck && rm -rf shellcheck-${SHELLCHECK}
shellcheck --version

printf "\nFetching kubeval kubernetes json schemas for v1.%s.0\n" "$(kubectl version --client=true --short=true | awk '{print $3}' | awk -F'.' '{print $2}')"
mkdir -p /usr/local/kubeval/schemas
git clone https://github.com/swade1987/kubernetes-json-schema.git
# shellcheck disable=SC2046
cp -R kubernetes-json-schema/v1.$(kubectl version --client=true --short=true | awk '{print $3}' | awk -F'.' '{print $2}').0-standalone-strict /usr/local/kubeval/schemas
rm -rf kubernetes-json-schema
