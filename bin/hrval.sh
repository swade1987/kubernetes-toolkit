#!/usr/bin/env bash

set -o errexit

HELM_RELEASE=${1}
IGNORE_VALUES=${2}
HELM_VER=${3-v2}

if test ! -f "${HELM_RELEASE}"; then
  echo "\"${HELM_RELEASE}\" Helm release file not found!"
  exit 1
fi

echo "Processing ${HELM_RELEASE}"

function isHelmRelease {
  KIND=$(yq e '.kind' "${1}")
  if [[ ${KIND} == "HelmRelease" ]]; then
      echo true
  else
    echo false
  fi
}

function download {
  CHART_REPO=$(yq e '.spec.chart.repository' "${1}")
  CHART_NAME=$(yq e '.spec.chart.name' "${1}")
  CHART_VERSION=$(yq e '.spec.chart.version' "${1}")
  CHART_DIR=${2}/${CHART_NAME}

  # Use the md5 sum of the repository URL so we don't keep adding a helm repo per helm chart.
  CHART_REPO_MD5=$(/bin/echo "$CHART_REPO" | /usr/bin/md5sum | cut -f1 -d" ")
  helm repo add "${CHART_REPO_MD5}" "${CHART_REPO}"
  helm repo update
  helm fetch --version "${CHART_VERSION}" --untar "${CHART_REPO_MD5}"/"${CHART_NAME}" --untardir "${2}"
  echo "${CHART_DIR}"
}

function clone {
  ORIGIN=$(git rev-parse --show-toplevel)
  GIT_REPO=$(yq e '.spec.chart.git' "${1}")
  if [[ -n "${GITHUB_TOKEN}" ]]; then
    BASE_URL=$(echo "${GIT_REPO}" | sed -e 's/ssh:\/\///' -e 's/git@//' -e 's/:/\//')
    GIT_REPO="https://${GITHUB_TOKEN}:x-oauth-basic@${BASE_URL}"
  elif [[ -n "${GITLAB_CI_TOKEN}" ]]; then
    BASE_URL=$(echo "${GIT_REPO}" | sed -e 's/ssh:\/\///' -e 's/git@//' -e 's/:/\//')
    GIT_REPO="https://gitlab-ci-token:${GITLAB_CI_TOKEN}@${BASE_URL}"
  fi
  GIT_REF=$(yq e '.spec.chart.ref' "${1}")
  CHART_PATH=$(yq e '.spec.chart.path' "${1}")
  cd "${2}"
  git init -q
  git remote add origin "${GIT_REPO}"
  git fetch -q origin
  git checkout -q "${GIT_REF}"
  cd "${ORIGIN}"
  echo "${2}"/"${CHART_PATH}"
}

function validate {
  if [[ $(isHelmRelease "${HELM_RELEASE}") == "false" ]]; then
    echo "\"${HELM_RELEASE}\" is not of kind HelmRelease!"
    exit 1
  fi

  TMPDIR=$(mktemp -d)
  CHART_PATH=$(yq e '.spec.chart.path' "${HELM_RELEASE}")

  if [[ "${CHART_PATH}" == null ]]; then
    echo "Downloading to ${TMPDIR}"
    CHART_DIR=$(download "${HELM_RELEASE}" "${TMPDIR}"| tail -n1)
  else
    echo "Cloning to ${TMPDIR}"
    CHART_DIR=$(clone "${HELM_RELEASE}" "${TMPDIR}"| tail -n1)
  fi

  HELM_RELEASE_NAME=$(yq e '.metadata.name' "${HELM_RELEASE}")
  HELM_RELEASE_NAMESPACE=$(yq e '.metadata.namespace' "${HELM_RELEASE}")

  if [[ ${IGNORE_VALUES} == "true" ]]; then
    echo "Ignoring Helm release values"
    echo "" > "${TMPDIR}"/"${HELM_RELEASE_NAME}".values.yaml
  else
    echo "Extracting values to ${TMPDIR}/${HELM_RELEASE_NAME}.values.yaml"
    yq e '.spec.values' "${HELM_RELEASE}" > "${TMPDIR}"/"${HELM_RELEASE_NAME}".values.yaml
  fi

  echo "Writing Helm release to ${TMPDIR}/${HELM_RELEASE_NAME}.release.yaml"
  if [[ ${HELM_VER} == "v3" ]]; then
    # Helm v3 bug: https://github.com/helm/helm/issues/6416
#    if [[ "${CHART_PATH}" ]]; then
#      helmv3 dependency build ${CHART_DIR}
#    fi
    helmv3 template "${HELM_RELEASE_NAME}" "${CHART_DIR}" \
      --namespace "${HELM_RELEASE_NAMESPACE}" \
      --skip-crds=true \
      -f "${TMPDIR}"/"${HELM_RELEASE_NAME}".values.yaml > "${TMPDIR}"/"${HELM_RELEASE_NAME}".release.yaml
  else
    if [[ "${CHART_PATH}" ]]; then
      helm dependency build "${CHART_DIR}"
    fi
    helm template "${CHART_DIR}" \
      --name "${HELM_RELEASE_NAME}" \
      --namespace "${HELM_RELEASE_NAMESPACE}" \
      -f "${TMPDIR}"/"${HELM_RELEASE_NAME}".values.yaml > "${TMPDIR}"/"${HELM_RELEASE_NAME}".release.yaml
  fi

  export KUBEVAL_SCHEMA_LOCATION=file:///usr/local/kubeval/schemas

  # Obtain the kubectl minor version
  KUBECTL_MINOR_VERSION=$(kubectl version --client --output=json | jq -r .clientVersion.gitVersion | cut -c2- | sed 's/.$/0/')

  echo "Validating Helm release ${HELM_RELEASE_NAME}.${HELM_RELEASE_NAMESPACE} against Kubernetes ${KUBECTL_MINOR_VERSION}"
  kubeval --strict --ignore-missing-schemas --kubernetes-version "${KUBECTL_MINOR_VERSION}" --force-color "${TMPDIR}"/"${HELM_RELEASE_NAME}".release.yaml

  echo "Validating Helm release ${HELM_RELEASE_NAME}.${HELM_RELEASE_NAMESPACE} against Rego policies"
  conftest test -p /policies ${TMPDIR}/${HELM_RELEASE_NAME}.release.yaml

  echo "Validating Helm release ${HELM_RELEASE_NAME}.${HELM_RELEASE_NAMESPACE} against Pluto deprecations"
  pluto detect -t k8s=v${KUBECTL_MINOR_VERSION} ${TMPDIR}/${HELM_RELEASE_NAME}.release.yaml
}

validate
