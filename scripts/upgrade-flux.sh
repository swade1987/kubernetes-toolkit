#!/usr/bin/env bash

###############################################################################
# Script Name     : upgrade-flux.sh
# Description     : Creates a pull request to upgrade Flux, and the kustomize
#                    and Helm versions Flux itself is built against
# Author          : Steve Wade
# Email           : steven@stevenwade.co.uk
###############################################################################
#
# Flux's own release doesn't state which kustomize/Helm CLI versions it was
# built against directly - it has to be derived:
#
#   1. The flux2 release body has a "Components changelog" section listing
#      kustomize-controller and helm-controller at their own versions.
#   2. kustomize-controller's go.mod, at that version, carries a literal
#      "// Pin kustomize to vX.Y.Z" comment - the real kustomize CLI version.
#   3. helm-controller's go.mod, at that version, imports helm.sh/helm/vN -
#      the module version *is* the Helm CLI release version.
#
# This keeps the toolkit's kustomize/Helm aligned with what Flux itself is
# compatible with, rather than independently chasing each tool's own latest -
# including across a Helm major version move, since HELM_VERSION carries no
# major-specific naming.

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

VERBOSE=true
DRY_RUN=true
LOG_FILE="${SCRIPT_DIR}/scripts/${SCRIPT_NAME}.log"
readonly INSTALL_SCRIPT="src/install-dependencies.sh"
readonly README="README.md"

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Checks Flux's latest release, derives the kustomize and Helm versions Flux
was built against, and (with --execute) opens a pull request updating
${INSTALL_SCRIPT} and ${README} to match.

Options:
    -h, --help         Show this help message
    -e, --execute      Execute changes (disabled by default)
    -l, --log FILE     Log output to specified file
EOF
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
    fi

    if [[ "${VERBOSE}" == "true" ]] || [[ "${level}" == "ERROR" ]]; then
        case "${level}" in
            ERROR)   echo -e "${RED}${timestamp} [${level}] ${message}${NC}" >&2 ;;
            WARN)    echo -e "${YELLOW}${timestamp} [${level}] ${message}${NC}" ;;
            SUCCESS) echo -e "${GREEN}${timestamp} [${level}] ${message}${NC}" ;;
            *)       echo "${timestamp} [${level}] ${message}" ;;
        esac
    fi
}

check_requirements() {
    local failed=false
    for cmd in "$@"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            log "ERROR" "${cmd} is required but not installed."
            failed=true
        fi
    done
    [[ "${failed}" == "true" ]] && exit 1
    return 0
}

# Fetch a file's content from a repo at a given ref, via the GitHub API.
# Reads the whole response before returning it, deliberately: a caller that
# piped this straight into "grep -m1" or "head -1" would close the pipe as
# soon as it found a match, and if base64 was still writing when that
# happened it would get a broken-pipe error that "set -o pipefail" turns
# into the whole pipeline failing - even though the value was already
# extracted correctly. Capturing fully here avoids that race entirely.
fetch_file() {
    local repo="$1" path="$2" ref="$3"
    gh api "repos/${repo}/contents/${path}?ref=${ref}" --jq '.content' | base64 -d
}

get_latest_flux_tag() {
    gh api repos/fluxcd/flux2/releases/latest --jq '.tag_name'
}

get_current_version() {
    local var="$1"
    grep -E "^${var}=" "${INSTALL_SCRIPT}" | head -1 | cut -d= -f2
}

# Extracts "<name> [vX.Y.Z]" from the release body's Components changelog
# section only, not the whole body (the CLI changelog section can mention
# the same repo names in unrelated PR titles).
get_component_version() {
    local body="$1" component="$2"
    awk '/^## Components changelog/{f=1;next} /^## /{f=0} f' <<<"$body" \
        | grep -E "^- ${component} \[v" \
        | grep -oE '\[v[0-9]+\.[0-9]+\.[0-9]+\]' \
        | tr -d '[]v'
}

get_kustomize_version() {
    local kc_tag="$1" content
    content="$(fetch_file "fluxcd/kustomize-controller" "go.mod" "v${kc_tag}")"
    grep -m1 "// Pin kustomize to v" <<<"$content" \
        | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
        | tr -d v
}

# Prints "<major> <version>", e.g. "4 4.2.4"
get_helm_version() {
    local hc_tag="$1" content
    content="$(fetch_file "fluxcd/helm-controller" "go.mod" "v${hc_tag}")"
    grep -m1 -E '^\s*helm\.sh/helm/v[0-9]+ v' <<<"$content" \
        | sed -E 's|.*helm\.sh/helm/v([0-9]+) v([0-9.]+).*|\1 \2|'
}

show_config() {
    log "INFO" "=== Configuration ==="
    log "INFO" "Flux target version:      ${FLUX_VERSION}"
    log "INFO" "kustomize target version: ${KUSTOMIZE_VERSION}"
    log "INFO" "Helm target version:      ${HELM_VERSION} (v${HELM_MAJOR} line)"
    log "INFO" "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'EXECUTE')"
    log "INFO" "===================="
}

update_install_script() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update FLUX/KUSTOMIZE/HELM_VERSION in ${INSTALL_SCRIPT}"
        return 0
    fi

    sed -i.bak -E "s/^FLUX=.*/FLUX=${FLUX_VERSION}/" "${INSTALL_SCRIPT}"
    sed -i.bak -E "s/^KUSTOMIZE=.*/KUSTOMIZE=${KUSTOMIZE_VERSION}/" "${INSTALL_SCRIPT}"
    sed -i.bak -E "s/^HELM_VERSION=.*/HELM_VERSION=${HELM_VERSION}/" "${INSTALL_SCRIPT}"
    rm -f "${INSTALL_SCRIPT}.bak"
    log "SUCCESS" "Updated ${INSTALL_SCRIPT}"
}

update_readme() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update flux/kustomize/Helm entries in ${README}"
        return 0
    fi

    sed -i.bak -E "s|(\[flux\]\(https://github.com/fluxcd/flux2\)) \(v[0-9.]+\)|\1 (v${FLUX_VERSION})|" "${README}"
    sed -i.bak -E "s|(\[kustomize\]\(https://github.com/kubernetes-sigs/kustomize\)) \(v[0-9.]+\)|\1 (v${KUSTOMIZE_VERSION})|" "${README}"
    sed -i.bak -E "s|\[Helm\]\(https://github.com/helm/helm\) \(v[0-9.]+\).*|[Helm](https://github.com/helm/helm) (v${HELM_VERSION}) - pinned to flux version|" "${README}"
    rm -f "${README}.bak"
    log "SUCCESS" "Updated ${README}"
}

create_pull_request() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would create pull request for Flux/kustomize/Helm upgrade"
        return 0
    fi

    local branch_name="flux/upgrade-to-v${FLUX_VERSION}"
    local commit_message="feat: upgrading flux to v${FLUX_VERSION}"

    log "INFO" "Creating and checking out branch..."
    git checkout -b "$branch_name" || { log "ERROR" "Failed to create branch"; exit 1; }

    log "INFO" "Committing changes..."
    git add .
    git commit -asm "$commit_message" || { log "ERROR" "Failed to commit changes"; exit 1; }

    log "INFO" "Pushing branch..."
    git push -u origin "$branch_name" || { log "ERROR" "Failed to push branch"; exit 1; }

    local body="Bumps flux from ${CURRENT_FLUX} to ${FLUX_VERSION}."

    if [[ "${KUSTOMIZE_VERSION}" != "${CURRENT_KUSTOMIZE}" ]]; then
        body="${body} Also bumps kustomize from ${CURRENT_KUSTOMIZE} to ${KUSTOMIZE_VERSION}, derived from kustomize-controller v${KC_VERSION}'s pinned version (flux v${FLUX_VERSION}'s Components changelog)."
    else
        body="${body} kustomize stays at ${KUSTOMIZE_VERSION} - flux v${FLUX_VERSION} still pins the same version via kustomize-controller v${KC_VERSION}."
    fi

    if [[ "${HELM_VERSION}" != "${CURRENT_HELM}" ]]; then
        body="${body}

Also bumps Helm from ${CURRENT_HELM} to ${HELM_VERSION} (helm-controller v${HC_VERSION} pins helm.sh/helm/v${HELM_MAJOR} v${HELM_VERSION})."
        if [[ "${HELM_MAJOR}" != "${CURRENT_HELM_MAJOR}" ]]; then
            body="${body} Note: this crosses a Helm major version (v${CURRENT_HELM_MAJOR} -> v${HELM_MAJOR}) - Helm's CLI surface can differ across majors, so review this one a bit more closely than a routine patch bump."
        fi
    else
        body="${body}

Helm stays at ${HELM_VERSION} - flux v${FLUX_VERSION} still pins the same version via helm-controller v${HC_VERSION}."
    fi

    log "INFO" "Creating pull request..."
    gh pr create \
        --title "$commit_message" \
        --body "$body" \
        --base main \
        --head "$branch_name" || { log "ERROR" "Failed to create PR"; exit 1; }

    log "SUCCESS" "Successfully created pull request for Flux upgrade"
}

main() {
    check_requirements "git" "gh" "jq" "sed" "awk"

    log "INFO" "Fetching latest flux2 release..."
    local latest_tag
    latest_tag="$(get_latest_flux_tag)"
    FLUX_VERSION="${latest_tag#v}"
    readonly FLUX_VERSION

    CURRENT_FLUX="$(get_current_version FLUX)"
    readonly CURRENT_FLUX

    if [[ "${FLUX_VERSION}" == "${CURRENT_FLUX}" ]]; then
        log "INFO" "Already on the latest flux release (v${FLUX_VERSION}); nothing to do."
        exit 0
    fi

    log "INFO" "Fetching v${FLUX_VERSION} release notes..."
    local body
    body="$(gh api "repos/fluxcd/flux2/releases/tags/${latest_tag}" --jq '.body')"

    KC_VERSION="$(get_component_version "$body" "kustomize-controller")"
    HC_VERSION="$(get_component_version "$body" "helm-controller")"
    readonly KC_VERSION HC_VERSION

    if [[ -z "${KC_VERSION}" || -z "${HC_VERSION}" ]]; then
        log "ERROR" "Could not find kustomize-controller/helm-controller versions in the Components changelog"
        exit 1
    fi

    log "INFO" "Deriving kustomize version from kustomize-controller v${KC_VERSION}..."
    KUSTOMIZE_VERSION="$(get_kustomize_version "${KC_VERSION}")"
    readonly KUSTOMIZE_VERSION

    log "INFO" "Deriving Helm version from helm-controller v${HC_VERSION}..."
    read -r HELM_MAJOR HELM_VERSION <<<"$(get_helm_version "${HC_VERSION}")"
    readonly HELM_MAJOR HELM_VERSION

    if [[ -z "${KUSTOMIZE_VERSION}" || -z "${HELM_VERSION}" ]]; then
        log "ERROR" "Could not derive kustomize/Helm versions from component go.mod files"
        exit 1
    fi

    CURRENT_KUSTOMIZE="$(get_current_version KUSTOMIZE)"
    CURRENT_HELM="$(get_current_version HELM_VERSION)"
    readonly CURRENT_KUSTOMIZE CURRENT_HELM
    CURRENT_HELM_MAJOR="${CURRENT_HELM%%.*}"
    readonly CURRENT_HELM_MAJOR

    show_config
    update_install_script
    update_readme
    create_pull_request
}

main "$@"
