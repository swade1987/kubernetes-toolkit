#!/usr/bin/env bash

###############################################################################
# Script Name     : upgrade-k8s.sh
# Description     : Creates a pull request to upgrade Kubernetes version
# Author          : Steve Wade
# Email           : steven@stevenwade.co.uk
###############################################################################

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch error in pipe
set -o pipefail

# Global constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

###############################################################################
# Variables
###############################################################################
VERBOSE=true
DRY_RUN=true
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"
KUBERNETES_VERSION=""

###############################################################################
# Usage help message
###############################################################################
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options] <kubernetes-version>

Creates a pull request to upgrade Kubernetes version in GitHub Actions and Makefile.

Options:
    -h, --help         Show this help message
    -e, --execute      Execute changes (disabled by default)
    -l, --log FILE     Log output to specified file

Example:
    ${SCRIPT_NAME} --execute 1.32.0
EOF
}

###############################################################################
# Functions
###############################################################################

# Logger function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

    # Always log to file if LOG_FILE is set
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
    fi

    # Only output to console if verbose is enabled or if it's an error
    if [[ "${VERBOSE}" == "true" ]] || [[ "${level}" == "ERROR" ]]; then
        case "${level}" in
            ERROR)
                echo -e "${RED}${timestamp} [${level}] ${message}${NC}" >&2
                ;;
            WARN)
                echo -e "${YELLOW}${timestamp} [${level}] ${message}${NC}"
                ;;
            SUCCESS)
                echo -e "${GREEN}${timestamp} [${level}] ${message}${NC}"
                ;;
            *)
                echo "${timestamp} [${level}] ${message}"
                ;;
        esac
    fi
}

# Function to check required commands
check_requirements() {
    local failed=false

    for cmd in "$@"; do
        if ! command -v "${cmd}" >/dev/null 2>&1; then
            log "ERROR" "${cmd} is required but not installed."
            failed=true
        fi
    done

    if [[ "${failed}" == "true" ]]; then
        exit 1
    fi
}

# Cleanup function
cleanup() {
    log "INFO" "Cleaning up..."
}

# Validate kubernetes version
validate_version() {
    if [[ ! $KUBERNETES_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "ERROR" "Invalid Kubernetes version format. Expected format: X.Y.Z"
        exit 1
    fi
}

# Show configuration
show_config() {
    local whoami=$(whoami)
    local branch_name="${whoami}/upgrade-k8s-to-${KUBERNETES_VERSION}"

    log "INFO" "=== Configuration ==="
    log "INFO" "Kubernetes Version: ${KUBERNETES_VERSION}"
    log "INFO" "Branch Name: ${branch_name}"
    log "INFO" "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'EXECUTE')"
    log "INFO" "===================="
}

# Update GitHub Actions workflows
update_github_actions() {
    local github_dir=".github/workflows"

    if [[ ! -d "$github_dir" ]]; then
        log "ERROR" "GitHub workflows directory not found: $github_dir"
        return 1
    fi

    log "INFO" "Updating GitHub Actions workflows..."

    find "$github_dir" -type f -name "*.yml" -o -name "*.yaml" | while read -r file; do
        if [[ "${DRY_RUN}" == "true" ]]; then
            log "INFO" "Would update Kubernetes version in: $file"
        else
            # Update the version in GitHub Actions workflow files
            sed -i.bak -E 's/(KUBERNETES_VERSION: ).*/\1'"${KUBERNETES_VERSION}"'/' "$file"
            rm "${file}.bak"
            log "SUCCESS" "Updated $file"
        fi
    done
}

# Update Makefile
update_makefile() {
    if [[ ! -f "Makefile" ]]; then
        log "ERROR" "Makefile not found"
        return 1
    fi

    log "INFO" "Updating Makefile..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update Kubernetes version in Makefile"
    else
        # Update the version in Makefile
        sed -i.bak 's/^KUBERNETES_VERSION := .*/KUBERNETES_VERSION := '"${KUBERNETES_VERSION}"'/' Makefile
        rm Makefile.bak
        log "SUCCESS" "Updated Makefile"
    fi
}

# Create pull request
create_pull_request() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would create pull request for version upgrade"
        return 0
    fi

    local whoami=$(whoami)
    local branch_name="${whoami}/upgrade-k8s-to-${KUBERNETES_VERSION}"
    local commit_message="feat: upgrading kubernetes to v${KUBERNETES_VERSION}"

    # Create and checkout branch
    log "INFO" "Creating and checking out branch..."
    git checkout -b "$branch_name" || { log "ERROR" "Failed to create branch"; exit 1; }

    # Commit changes
    log "INFO" "Committing changes..."
    git add .
    git commit -asm "$commit_message" || { log "ERROR" "Failed to commit changes"; exit 1; }

    # Push branch
    log "INFO" "Pushing branch..."
    git push -u origin "$branch_name" || { log "ERROR" "Failed to push branch"; exit 1; }

    # Create pull request
    log "INFO" "Creating pull request..."
    gh pr create \
        --title "$commit_message" \
        --body "feat: updating kubernetes version to ${KUBERNETES_VERSION}." \
        --base master \
        --head "$branch_name" || { log "ERROR" "Failed to create PR"; exit 1; }

    log "SUCCESS" "Successfully created pull request for Kubernetes version upgrade"
}

###############################################################################
# Main Script
###############################################################################

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
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
            if [[ -z "$KUBERNETES_VERSION" ]]; then
                KUBERNETES_VERSION="$1"
            else
                log "ERROR" "Unexpected argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if kubernetes version is provided
if [[ -z "$KUBERNETES_VERSION" ]]; then
    log "ERROR" "Kubernetes version is required"
    usage
    exit 1
fi

# Ensure cleanup happens on script exit
trap cleanup EXIT

# Check for required tools
check_requirements "git" "gh" "sed"

# Main logic
main() {
    validate_version
    show_config
    update_github_actions
    update_makefile
    create_pull_request
}

# Run main function
main "$@"
