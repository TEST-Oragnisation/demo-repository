#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./create-branch.sh <type> <ticket-id> <short-description> --base <branch>

Types:
  feature | bugfix | hotfix | chore | refactor | docs | spike

Base rules for this repository:
  feature, bugfix, chore, refactor, docs, spike: develop
  hotfix: main (production)

Examples:
  ./create-branch.sh feature 142 po-approval-workflow --base develop
  ./create-branch.sh hotfix 301 payment-advice-rounding --base main
EOF
}

if [[ $# -ne 5 ]]; then
    echo "WARNING: --base is required; no branch was created." >&2
    usage >&2
    exit 2
fi

if [[ "$4" != "--base" || -z "$5" ]]; then
    echo "Invalid base argument: use --base <branch>; no branch was created." >&2
    usage >&2
    exit 2
fi

TYPE="$1"
TICKET="$2"
DESCRIPTION="$3"
BASE="$5"

if [[ ! "$TYPE" =~ ^(feature|bugfix|hotfix|chore|refactor|docs|spike)$ ]]; then
    echo "Invalid type: $TYPE" >&2
    usage >&2
    exit 2
fi

if [[ ! "$TICKET" =~ ^[0-9]+$ ]]; then
    echo "Invalid ticket ID: expected numbers only (for example: 142)." >&2
    exit 2
fi

if [[ ! "$DESCRIPTION" =~ ^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$ ]]; then
    echo "Invalid description: use letters, numbers, and hyphens." >&2
    exit 2
fi

if [[ "$TYPE" == "hotfix" ]]; then
    if [[ "$BASE" != "main" ]]; then
        echo "Hotfix branches in this repository must use the production base 'main'." >&2
        exit 2
    fi
elif [[ "$BASE" != "develop" ]]; then
    echo "Development branches in this repository must use 'develop'." >&2
    exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if ! REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
    echo "The script must be located inside a Git repository." >&2
    exit 1
fi

if ! git -C "$REPO_ROOT" remote get-url origin >/dev/null 2>&1; then
    echo "This repository does not have an 'origin' remote." >&2
    exit 1
fi

if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
    echo "Working tree is not clean. Commit, stash, or remove changes before creating a branch." >&2
    exit 1
fi

BRANCH="$TYPE/$TICKET-$DESCRIPTION"

if ! git check-ref-format --branch "$BRANCH" >/dev/null; then
    echo "Generated branch name is not a valid Git branch name: $BRANCH" >&2
    exit 2
fi

if ! remote_branches="$(git -C "$REPO_ROOT" ls-remote --heads origin)"; then
    echo "Could not check branches on origin; refusing to create a possibly duplicate branch." >&2
    exit 1
fi

local_same_name="$(
    git -C "$REPO_ROOT" for-each-ref --format='%(refname:short)' refs/heads |
        grep -F -x -- "$BRANCH" || true
)"
remote_same_name="$(
    printf '%s\n' "$remote_branches" |
        awk '{ sub("refs/heads/", "", $2); print $2 }' |
        grep -F -x -- "$BRANCH" || true
)"

if [[ -n "$local_same_name" || -n "$remote_same_name" ]]; then
    echo "Branch name already exists; refusing to create duplicate '$BRANCH'." >&2
    [[ -z "$local_same_name" ]] || echo "Local branch: $local_same_name" >&2
    [[ -z "$remote_same_name" ]] || echo "Remote branch: origin/$remote_same_name" >&2
    exit 1
fi

local_ticket_branch="$(
    git -C "$REPO_ROOT" for-each-ref --format='%(refname:short)' refs/heads |
        grep -E "^[^/]+/${TICKET}-" || true
)"
remote_ticket_branch="$(
    printf '%s\n' "$remote_branches" |
        awk '{ sub("refs/heads/", "", $2); print $2 }' |
        grep -E "^[^/]+/${TICKET}-" || true
)"

if [[ -n "$local_ticket_branch" || -n "$remote_ticket_branch" ]]; then
    echo "Ticket ID $TICKET is already used by an existing branch; refusing to create another branch for this ticket." >&2
    if [[ -n "$local_ticket_branch" ]]; then
        printf 'Local branch(es):\n%s\n' "$local_ticket_branch" >&2
    fi
    if [[ -n "$remote_ticket_branch" ]]; then
        printf 'Remote branch(es):\n%s\n' "$remote_ticket_branch" >&2
    fi
    exit 1
fi

if ! git -C "$REPO_ROOT" fetch --no-tags origin "refs/heads/$BASE:refs/remotes/origin/$BASE"; then
    echo "Could not fetch origin/$BASE. Check that the remote branch exists and is accessible." >&2
    exit 1
fi
git -C "$REPO_ROOT" switch --no-track --create "$BRANCH" "refs/remotes/origin/$BASE"

echo "Created branch: $BRANCH"
echo "Based on: origin/$BASE"