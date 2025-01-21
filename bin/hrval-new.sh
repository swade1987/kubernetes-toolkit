#!/usr/bin/env bash

set -o errexit

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Function to check if a file is a HelmRelease
function is_helm_release() {
    local yaml=$1
    local kind
    kind=$(yq e '.kind' "$yaml")
    [[ $kind == "HelmRelease" ]] && printf "true" || printf "false"
}

# Function to download a Helm chart
function download_chart() {
    local helm_release=$1
    local target_dir=$2
    local helm_username=$3
    local helm_password=$4
    local chart_repo chart_name chart_version chart_dir chart_repo_md5

    chart_repo=$(yq e '.spec.chart.repository' "${helm_release}")
    chart_name=$(yq e '.spec.chart.name' "${helm_release}")
    chart_version=$(yq e '.spec.chart.version' "${helm_release}")
    chart_dir=${target_dir}/${chart_name}
    chart_repo_md5=$(/bin/echo "$chart_repo" | /usr/bin/md5sum | cut -f1 -d" ")

    if [[ -n "${helm_username}" && -n "${helm_password}" ]]; then
        helm repo add "${chart_repo_md5}" "${chart_repo}" --username "${helm_username}" --password "${helm_password}"
    else
        helm repo add "${chart_repo_md5}" "${chart_repo}"
    fi

    helm repo update
    helm fetch --version "${chart_version}" --untar "${chart_repo_md5}"/"${chart_name}" --untardir "${target_dir}"
    printf "%s" "${chart_dir}"
}

# Function to clone a Git repository
function clone_repo() {
    local helm_release=$1
    local target_dir=$2
    local origin git_repo git_ref chart_path

    origin=$(git rev-parse --show-toplevel)
    git_repo=$(yq e '.spec.chart.git' "${helm_release}")
    git_ref=$(yq e '.spec.chart.ref' "${helm_release}")
    chart_path=$(yq e '.spec.chart.path' "${helm_release}")

    if [[ -n "${GITHUB_TOKEN}" ]]; then
        git_repo=$(echo "${git_repo}" | sed -e 's|ssh://||' -e 's|git@|https://|' -e 's|:|/|')
        git_repo="https://${GITHUB_TOKEN}:x-oauth-basic@${git_repo#https://}"
    elif [[ -n "${GITLAB_CI_TOKEN}" ]]; then
        git_repo=$(echo "${git_repo}" | sed -e 's|ssh://||' -e 's|git@|https://|' -e 's|:|/|')
        git_repo="https://gitlab-ci-token:${GITLAB_CI_TOKEN}@${git_repo#https://}"
    fi

    cd "${target_dir}"
    git init -q
    git remote add origin "${git_repo}"
    git fetch -q origin
    git checkout -q "${git_ref}"
    cd "${origin}"
    printf "%s/%s" "${target_dir}" "${chart_path}"
}

# Function to perform validation using kubeconform and pluto
function perform_validations() {
    local release_file=$1
    local release_name=$2
    local release_namespace=$3

    flux_version=$(flux version --client | awk '{print $2}')
    kubernetes_version=$(kubectl version --client --output=json | jq -r .clientVersion.gitVersion | cut -c2- | sed 's/.$/0/')

    kubeconform_flags=("-skip=Secret")
    kubeconform_config=("-strict" "-ignore-missing-schemas" "-schema-location" "default" "-schema-location" "/tmp/flux-schemas" "-schema-location" "/tmp/kubernetes-schemas" "-verbose" "-output" "pretty" "-exit-on-error")

    printf "Validating Helm release %s.%s against Flux %s schemas and Kubernetes %s schemas\n" "${release_name}" "${release_namespace}" "${flux_version}" "${kubernetes_version}"
    kubeconform "${kubeconform_flags[@]}" "${kubeconform_config[@]}" "${release_file}"

    printf "Validating Helm release %s.%s against %s deprecations\n" "${release_name}" "${release_namespace}" "${kubernetes_version}"
    pluto detect -t "k8s=v${kubernetes_version}" "${release_file}"
}

# Function to validate a Helm release
function validate_helm_release() {
    local helm_release=$1
    local ignore_values=$2
    local helm_version=$3
    local helm_username=$4
    local helm_password=$5
    local tmpdir chart_dir helm_release_name helm_release_namespace

    if [[ $(is_helm_release "${helm_release}") == "false" ]]; then
        printf "Error: %s is not of kind HelmRelease, exiting!\n" "${helm_release}"
        return 1
    fi

    tmpdir=$(mktemp -d)
    chart_path=$(yq e '.spec.chart.path' "${helm_release}")

    if [[ "${chart_path}" == null ]]; then
        printf "Downloading to %s\n" "${tmpdir}"
        chart_dir=$(download_chart "${helm_release}" "${tmpdir}" "${helm_username}" "${helm_password}")
    else
        printf "Cloning to %s\n" "${tmpdir}"
        chart_dir=$(clone_repo "${helm_release}" "${tmpdir}")
    fi

    helm_release_name=$(yq e '.metadata.name' "${helm_release}")
    helm_release_namespace=$(yq e '.metadata.namespace' "${helm_release}")

    if [[ ${ignore_values} == "true" ]]; then
        printf "Ignoring Helm release values\n"
        echo "" > "${tmpdir}/${helm_release_name}.values.yaml"
    else
        printf "Extracting values to %s/%s.values.yaml\n" "${tmpdir}" "${helm_release_name}"
        yq e '.spec.values' "${helm_release}" > "${tmpdir}/${helm_release_name}.values.yaml"
    fi

    printf "Writing Helm release to %s/%s.release.yaml\n" "${tmpdir}" "${helm_release_name}"
    if [[ ${helm_version} == "v3" ]]; then
        helmv3 template "${helm_release_name}" "${chart_dir}" \
            --namespace "${helm_release_namespace}" \
            --skip-crds=true \
            -f "${tmpdir}/${helm_release_name}.values.yaml" > "${tmpdir}/${helm_release_name}.release.yaml"
    else
        if [[ "${chart_path}" ]]; then
            helm dependency build "${chart_dir}"
        fi
        helm template "${chart_dir}" \
            --name "${helm_release_name}" \
            --namespace "${helm_release_namespace}" \
            -f "${tmpdir}/${helm_release_name}.values.yaml" > "${tmpdir}/${helm_release_name}.release.yaml"
    fi

    # Perform validations
    perform_validations "${tmpdir}/${helm_release_name}.release.yaml" "${helm_release_name}" "${helm_release_namespace}"
}

# Main function
function main() {
    local helm_release=$1
    local ignore_values=$2
    local helm_version=${3:-v2}
    local helm_username=$4
    local helm_password=$5

    if [[ ! -f "${helm_release}" ]]; then
        printf "Error: %s Helm release file not found!\n" "${helm_release}"
        return 1
    fi

    printf "Processing %s\n" "${helm_release}"
    validate_helm_release "${helm_release}" "${ignore_values}" "${helm_version}" "${helm_username}" "${helm_password}"
}

# Call the main function with all script arguments
main "$@"
