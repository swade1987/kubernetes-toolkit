#!/usr/bin/env bash

###############################################################################
# Library         : signed-pr.sh
# Description     : Pushes an empty branch, then commits the working tree's
#                    current changes onto it via GitHub's own API, and opens
#                    a pull request - shared by the upgrade-*.sh scripts.
###############################################################################
#
# A plain "git commit" run in CI produces an unsigned commit (there's no
# signing key configured on the runner), which fails this repo's
# "required_signatures" branch ruleset rule and blocks the resulting PR from
# merging - it doesn't matter that every status check passes. GitHub's
# createCommitOnBranch GraphQL mutation sidesteps this entirely: it creates
# the commit server-side, signed by GitHub itself, the same way a squash
# merge is. The trade-off is that it can only add/replace file *content* at
# a path (no permission-bit or rename changes) - fine for these scripts,
# which only ever edit existing text files in place.
#
# Requires "log" to already be defined by the sourcing script (all of them
# define an identical one), and expects to be called with the working tree
# already containing the uncommitted changes to ship - it reads their
# current on-disk content directly, not a git diff.
#
# Usage: create_signed_pr <branch_name> <commit_headline> <pr_title> <pr_body>

create_signed_pr() {
    local branch_name="$1" commit_headline="$2" pr_title="$3" pr_body="$4"

    local base_sha repo
    base_sha="$(git rev-parse HEAD)"
    repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"

    log "INFO" "Pushing branch..."
    git push origin "HEAD:refs/heads/${branch_name}" || { log "ERROR" "Failed to push branch"; exit 1; }

    local changed_files
    changed_files="$(git diff --name-only HEAD)"
    if [[ -z "${changed_files}" ]]; then
        log "ERROR" "No changed files to commit"
        exit 1
    fi

    log "INFO" "Building a signed commit via the GitHub API..."
    local file_changes_json
    file_changes_json="$(
        while IFS= read -r f; do
            jq -n --arg path "$f" --arg contents "$(base64 <"$f" | tr -d '\n')" \
                '{path: $path, contents: $contents}'
        done <<<"${changed_files}" | jq -s '{additions: .}'
    )"

    # DCO checks the commit *message* for a "Signed-off-by:" trailer - a
    # completely separate thing from the commit's cryptographic signature,
    # which this mutation already provides regardless. "git commit -s" used
    # to add this trailer automatically; creating the commit via the API
    # instead means it has to be added explicitly here.
    local signoff_name signoff_email
    signoff_name="$(git config user.name)"
    signoff_email="$(git config user.email)"

    local payload response commit_oid
    payload="$(jq -n \
        --arg repo "$repo" \
        --arg branch "$branch_name" \
        --arg headline "$commit_headline" \
        --arg body "Signed-off-by: ${signoff_name} <${signoff_email}>" \
        --arg oid "$base_sha" \
        --argjson fileChanges "$file_changes_json" \
        '{
            query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid } } }",
            variables: {
                input: {
                    branch: { repositoryNameWithOwner: $repo, branchName: $branch },
                    message: { headline: $headline, body: $body },
                    expectedHeadOid: $oid,
                    fileChanges: $fileChanges
                }
            }
        }'
    )"

    response="$(echo "${payload}" | gh api graphql --input -)"
    commit_oid="$(echo "${response}" | jq -r '.data.createCommitOnBranch.commit.oid // empty')"

    if [[ -z "${commit_oid}" ]]; then
        log "ERROR" "Failed to create signed commit: ${response}"
        exit 1
    fi
    log "SUCCESS" "Created signed commit ${commit_oid}"

    log "INFO" "Creating pull request..."
    gh pr create \
        --title "$pr_title" \
        --body "$pr_body" \
        --base main \
        --head "$branch_name" || { log "ERROR" "Failed to create PR"; exit 1; }

    log "SUCCESS" "Successfully created pull request"
}
