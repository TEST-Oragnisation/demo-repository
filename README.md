![Auto Assign](https://github.com/TEST-Oragnisation/demo-repository/actions/workflows/auto-assign.yml/badge.svg)

![Proof HTML](https://github.com/TEST-Oragnisation/demo-repository/actions/workflows/proof-html.yml/badge.svg)

# Welcome to your organization's demo respository
This code repository (or "repo") is designed to demonstrate the best GitHub has to offer with the least amount of noise.

The repo includes an `index.html` file (so it can render a web page), two GitHub Actions workflows, and a CSS stylesheet dependency.

## Branching

Create branches with `create-branch.sh`. Branch names use
`<type>/<numeric-ticket-id>-<short-description>`:

```bash
./create-branch.sh feature 142 po-approval-workflow --base develop
./create-branch.sh feature 143 po-approval-workflow --base develop
./create-branch.sh hotfix 301 payment-rounding --base main
```

Descriptions may contain uppercase or lowercase letters, numbers, and
underscores. Single hyphens may separate words. A description must contain at
least one letter or number and may not exceed 20 characters.

Development branches use `develop` as their base and pull requests target
`develop`. Supported types are `feature`, `bugfix`, `hotfix`, `chore`,
`refactor`, `docs`, and `spike`. Hotfix branches start from `main`, the
production branch, and their pull requests target `main`. After a hotfix is
merged and verified on `main`, forward-port it to `develop` if needed.
Branch-name validation is skipped when the PR source is an existing base branch
(`main`, `develop`, or `iith`), allowing promotions such as `develop` to `main`
without applying feature-branch naming rules. New branches still must follow
the naming convention and target the correct base.
Descriptions are required and may contain uppercase or lowercase letters,
numbers, and underscores, with single hyphens separating words and a maximum
length of 20 characters. Spaces, consecutive hyphens, and descriptions made
only of underscores or other non-alphanumeric characters are not allowed.
Ticket IDs may only be used by one branch in this repository. The script checks
current local and remote branches. Deleted branches and concurrent branch
creation are not centrally tracked, so the ticket system remains the authority
for uniqueness.

On pull requests, the branch-name check validates the name format,
description-length limit, and expected PR target. It does not check PR history
for reused ticket IDs or require the PR branch to contain the latest target
branch commit. No branch naming check runs on pushes.
