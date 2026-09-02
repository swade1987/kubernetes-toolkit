#!/usr/bin/env bash

###############################################################################
# Script Name     : upgrade-flux-operator.sh
# Description     : Creates a pull request to upgrade the Flux Operator
# Author          : Steve Wade
# Email           : steven@stevenwade.co.uk
###############################################################################
#
# Unlike flux2 (see upgrade-flux.sh), the Flux Operator is a standalone
# project with its own releases - no derivation chain needed, just compare
# against its latest GitHub release directly.

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

Checks the Flux Operator's latest release and (with --execute) opens a pull
request updating ${INSTALL_SCRIPT} and ${README} to match.

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

get_latest_tag() {
    gh api repos/controlplaneio-fluxcd/flux-operator/releases/latest --jq '.tag_name'
}

get_current_version() {
    grep -E "^FLUX_OPERATOR=" "${INSTALL_SCRIPT}" | head -1 | cut -d= -f2
}

show_config() {
    log "INFO" "=== Configuration ==="
    log "INFO" "Flux Operator target version: ${TARGET_VERSION}"
    log "INFO" "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'EXECUTE')"
    log "INFO" "===================="
}

update_install_script() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update FLUX_OPERATOR in ${INSTALL_SCRIPT}"
        return 0
    fi
    sed -i.bak -E "s/^FLUX_OPERATOR=.*/FLUX_OPERATOR=${TARGET_VERSION}/" "${INSTALL_SCRIPT}"
    rm -f "${INSTALL_SCRIPT}.bak"
    log "SUCCESS" "Updated ${INSTALL_SCRIPT}"
}

update_readme() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update flux operator entry in ${README}"
        return 0
    fi
    sed -i.bak -E "s|(\[flux operator\]\(https://github.com/controlplaneio-fluxcd/flux-operator\)) \(v[0-9.]+\)|\1 (v${TARGET_VERSION})|" "${README}"
    rm -f "${README}.bak"
    log "SUCCESS" "Updated ${README}"
}

create_pull_request() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would create pull request for Flux Operator upgrade"
        return 0
    fi

    local branch_name="flux-operator/upgrade-to-v${TARGET_VERSION}"
    local commit_message="feat: upgrading flux operator to v${TARGET_VERSION}"

    log "INFO" "Creating and checking out branch..."
    git checkout -b "$branch_name" || { log "ERROR" "Failed to create branch"; exit 1; }

    log "INFO" "Committing changes..."
    git add .
    git commit -asm "$commit_message" || { log "ERROR" "Failed to commit changes"; exit 1; }

    log "INFO" "Pushing branch..."
    git push -u origin "$branch_name" || { log "ERROR" "Failed to push branch"; exit 1; }

    log "INFO" "Creating pull request..."
    gh pr create \
        --title "$commit_message" \
        --body "Bumps the Flux Operator from ${CURRENT_VERSION} to ${TARGET_VERSION}." \
        --base main \
        --head "$branch_name" || { log "ERROR" "Failed to create PR"; exit 1; }

    log "SUCCESS" "Successfully created pull request for Flux Operator upgrade"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            *)
                log "ERROR" "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    check_requirements "git" "gh" "sed"

    log "INFO" "Fetching latest Flux Operator release..."
    local latest_tag
    latest_tag="$(get_latest_tag)"
    TARGET_VERSION="${latest_tag#v}"
    readonly TARGET_VERSION

    CURRENT_VERSION="$(get_current_version)"
    readonly CURRENT_VERSION

    if [[ "${TARGET_VERSION}" == "${CURRENT_VERSION}" ]]; then
        log "INFO" "Already on the latest Flux Operator release (v${TARGET_VERSION}); nothing to do."
        exit 0
    fi

    show_config
    update_install_script
    update_readme
    create_pull_request
}

main "$@"
