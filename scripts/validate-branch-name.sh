#!/usr/bin/env bash
# Exit 0 when a branch name matches this repository's naming policy.

set -euo pipefail

if [[ $# -ne 1 || -z "${1:-}" ]]; then
    echo "Usage: validate-branch-name.sh <branch-name>" >&2
    exit 1
fi

BRANCH_NAME="$1"

if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "develop" || "$BRANCH_NAME" == "iith" ]]; then
    exit 0
fi

if [[ ! "$BRANCH_NAME" =~ ^(feature|bugfix|hotfix|chore|refactor|docs|spike)/[0-9]+-[A-Za-z0-9_]+(-[A-Za-z0-9_]+)*$ ]]; then
    echo "Invalid branch name '$BRANCH_NAME'. Expected <type>/<numeric-ticket-id>-<description> (letters, numbers, underscores, and single hyphens)." >&2
    echo "Allowed types: feature, bugfix, hotfix, chore, refactor, docs, spike." >&2
    exit 1
fi

DESCRIPTION="${BRANCH_NAME#*/}"
DESCRIPTION="${DESCRIPTION#*-}"

if [[ ! "$DESCRIPTION" =~ [A-Za-z0-9] ]]; then
    echo "Description in '$BRANCH_NAME' must contain at least one letter or number." >&2
    exit 1
fi

if (( ${#DESCRIPTION} > 20 )); then
    echo "Description in '$BRANCH_NAME' exceeds the 20-character maximum." >&2
    exit 1
fi

exit 0
