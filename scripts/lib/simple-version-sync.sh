#!/usr/bin/env bash

###############################################################################
# Library         : simple-version-sync.sh
# Description     : Checks a tool's latest GitHub release against what's
#                    currently pinned in src/install-dependencies.sh, and
#                    (with --execute) opens a PR to bump it via create_signed_pr.
###############################################################################
#
# Shared by the standalone-tool upgrade scripts (kubeconform, pluto,
# istioctl - each a simple GitHub-releases project with no derivation
# chain, unlike flux's kustomize/Helm versions). Requires "log",
# "create_signed_pr", "DRY_RUN" and "INSTALL_SCRIPT" to already be defined
# by the sourcing script. Also updates README.md's tool table, matching
# upgrade-flux.sh / upgrade-flux-operator.sh - the README's markdown link
# for the tool must read "[<display name>](https://github.com/<repo>) (vX.Y.Z)"
# with the repo exactly matching the <owner/repo> argument.
#
# Usage: sync_simple_tool_version <display name> <owner/repo> <VAR_NAME> <tag prefix, "v" or "">
# Returns 1 (no error, just "nothing to do") if already in sync.

sync_simple_tool_version() {
    local display_name="$1" repo="$2" var_name="$3" tag_prefix="$4"
    local readme="README.md"

    log "INFO" "Fetching latest ${display_name} release..."
    local latest_tag target_version current_version
    latest_tag="$(gh api "repos/${repo}/releases/latest" --jq '.tag_name')"
    target_version="${latest_tag#"${tag_prefix}"}"
    current_version="$(grep -E "^${var_name}=" "${INSTALL_SCRIPT}" | head -1 | cut -d= -f2)"

    log "INFO" "${display_name}: current=${current_version} latest=${target_version}"

    if [[ "${target_version}" == "${current_version}" ]]; then
        log "INFO" "Already on the latest ${display_name} release (${target_version}); nothing to do."
        return 1
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log "INFO" "Would update ${var_name} in ${INSTALL_SCRIPT} to ${target_version}"
        log "INFO" "Would update ${display_name} entry in ${readme}"
        return 0
    fi

    sed -i.bak -E "s/^${var_name}=.*/${var_name}=${target_version}/" "${INSTALL_SCRIPT}"
    rm -f "${INSTALL_SCRIPT}.bak"
    log "SUCCESS" "Updated ${INSTALL_SCRIPT}"

    local readme_version="${target_version}"
    [[ "${readme_version}" != v* ]] && readme_version="v${readme_version}"
    sed -i.bak -E "s|(\[${display_name}\]\(https://github.com/${repo}\))[[:space:]]+\(v[0-9.]+\)|\1 (${readme_version})|" "${readme}"
    rm -f "${readme}.bak"
    log "SUCCESS" "Updated ${readme}"

    local branch_slug
    branch_slug="$(echo "${var_name}" | tr '[:upper:]' '[:lower:]')"
    local branch_name="${branch_slug}/upgrade-to-${target_version}"
    local commit_message="feat: upgrading ${display_name} to ${target_version}"

    create_signed_pr "$branch_name" "$commit_message" "$commit_message" \
        "Bumps ${display_name} from ${current_version} to ${target_version}."
}
