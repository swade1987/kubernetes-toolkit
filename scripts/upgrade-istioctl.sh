#!/usr/bin/env bash

###############################################################################
# Script Name     : upgrade-istioctl.sh
# Description     : Creates a pull request to upgrade istioctl to its
#                    latest GitHub release
###############################################################################

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# shellcheck source=lib/signed-pr.sh
source "${SCRIPT_DIR}/scripts/lib/signed-pr.sh"
# shellcheck source=lib/simple-version-sync.sh
source "${SCRIPT_DIR}/scripts/lib/simple-version-sync.sh"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

VERBOSE=true
DRY_RUN=true
LOG_FILE="${SCRIPT_DIR}/scripts/${SCRIPT_NAME}.log"
readonly INSTALL_SCRIPT="src/install-dependencies.sh"

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Checks istioctl's latest GitHub release and (with --execute) opens a
pull request updating ${INSTALL_SCRIPT} to match.

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
    check_requirements "git" "gh" "jq" "sed"
    sync_simple_tool_version "istioctl" "istio/istio" "ISTIOCTL" "" || exit 0
}

parse_args "$@"
main
