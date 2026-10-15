#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./create-branch.sh <type> <ticket-id> <short-description> [--base <branch>]

Types:
  feature | bugfix | hotfix | chore | refactor | docs | spike

Base rules for this repository:
  Default: develop
  feature, bugfix, chore, refactor, docs, spike: develop
  hotfix: main (production)

Examples:
  ./create-branch.sh feature 142 po-approval-workflow
  ./create-branch.sh hotfix 301 payment-advice-rounding --base main
EOF
}

if [[ $# -ne 3 && $# -ne 5 ]] || { [[ $# -eq 5 ]] && [[ "$4" != "--base" ]]; }; then
    usage >&2
    exit 2
fi

TYPE="$1"
TICKET="$2"
DESCRIPTION="$3"
BASE="develop"
if [[ $# -eq 5 ]]; then
    BASE="$5"
fi

if [[ ! "$TYPE" =~ ^(feature|bugfix|hotfix|chore|refactor|docs|spike)$ ]]; then
    echo "Invalid type: $TYPE" >&2
    usage >&2
    exit 2
fi

if [[ ! "$TICKET" =~ ^[0-9]+$ ]]; then
    echo "Invalid ticket ID: expected numbers only (for example: 142)." >&2
    exit 2
fi

if [[ ! "$DESCRIPTION" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "Invalid description: use lowercase letters, numbers, and hyphens." >&2
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

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Local branch already exists: $BRANCH" >&2
    exit 1
fi

if ! git check-ref-format --branch "$BRANCH" >/dev/null; then
    echo "Generated branch name is not a valid Git branch name: $BRANCH" >&2
    exit 2
fi

if ! remote_branch="$(git -C "$REPO_ROOT" ls-remote --heads origin "refs/heads/$BRANCH")"; then
    echo "Could not check whether origin/$BRANCH already exists." >&2
    exit 1
fi
if [[ -n "$remote_branch" ]]; then
    echo "Remote branch already exists: origin/$BRANCH" >&2
    exit 1
fi

if ! git -C "$REPO_ROOT" fetch --no-tags origin "refs/heads/$BASE:refs/remotes/origin/$BASE"; then
    echo "Could not fetch origin/$BASE. Check that the remote branch exists and is accessible." >&2
    exit 1
fi
git -C "$REPO_ROOT" switch --no-track --create "$BRANCH" "refs/remotes/origin/$BASE"

echo "Created branch: $BRANCH"
echo "Based on: origin/$BASE"
