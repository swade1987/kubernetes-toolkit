#!/usr/bin/env bash

set -eu

IGNORE_VALUES=false
KUBE_VERSION=1.18.0
HELM_VERSION=v3

TMP_DIR="$(mktemp -d)"

function get_targets {
  find . -maxdepth 3 -name kustomization.yaml -exec dirname {} \;
  find . -mindepth 4 -maxdepth 4 -name kustomization.yaml -exec dirname {} \; | sort | uniq | grep variant
}

function patched_kustomization {
  local env_path flux_patch
  env_path=$1
  flux_patch="$env_path/flux-patch.yaml"
  kustomize create
  kustomize edit add resource "$env_path"
  if [ -s "$flux_patch" ]; then
    echo "patches:" >> kustomization.yaml
    echo "- ${flux_patch}" >> kustomization.yaml
  fi
}

function build {
  local ref="$1"
  printf "\n\nChecking out ref: %s\n" "$ref"
  git checkout "$ref" --quiet
  for env_path in $(get_targets); do
    local build_dir
    if ! [ -d "$env_path" ]; then continue; fi
    build_dir="$TMP_DIR/$ref/${env_path#*kustomize/}"
    printf "\n\nCreating build directory: %s\n" "$build_dir"
    mkdir -p "$build_dir"
    patched_kustomization "$env_path"
    echo "Running kustomize"
    kustomize build . -o "$build_dir"
    rm kustomization.yaml
  done
}

function changed_yamls {
  git diff \
    --no-index \
    --diff-filter AM \
    --name-only \
    "$TMP_DIR/$CI_MERGE_REQUEST_DIFF_BASE_SHA" "$TMP_DIR/$CI_COMMIT_SHA" \
  | grep -E '\.(yaml|yml)$'
}

function is_helm_release {
  local kind yaml
  yaml=$1
  kind=$(yq r "$yaml" kind)
  if [[ $kind == "HelmRelease" ]]; then
      echo true
  else
    echo false
  fi
}

function main {
  local exit_code hrval_output returned
  exit_code=0

  build "$CI_COMMIT_SHA"
  build "$CI_MERGE_REQUEST_DIFF_BASE_SHA"

  set +e
  for yaml in $(changed_yamls); do
    if [[ $(is_helm_release "$yaml") == "true" ]]; then
      hrval_output=$(/usr/local/bin/hrval.sh "$yaml" "${IGNORE_VALUES}" "${KUBE_VERSION}" "${HELM_VERSION}")
      returned=$?
      if [[ $returned -ne 0 ]]; then
        exit_code=$returned
      fi
      printf "%s\n\n" "$hrval_output"
    fi
  done
  set -e

  exit $exit_code
}

main
