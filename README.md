![Auto Assign](https://github.com/TEST-Oragnisation/demo-repository/actions/workflows/auto-assign.yml/badge.svg)

![Proof HTML](https://github.com/TEST-Oragnisation/demo-repository/actions/workflows/proof-html.yml/badge.svg)

# Welcome to your organization's demo respository
This code repository (or "repo") is designed to demonstrate the best GitHub has to offer with the least amount of noise.

The repo includes an `index.html` file (so it can render a web page), two GitHub Actions workflows, and a CSS stylesheet dependency.

## Branching

Create branches with `create-branch.sh`. Branch names use
`<type>/<numeric-ticket-id>-<short-description>`:

```bash
./create-branch.sh feature 142 po-approval-workflow
./create-branch.sh feature 142 po-Approval-Workflow
./create-branch.sh hotfix 301 payment-advice-rounding
```

Descriptions may contain uppercase or lowercase letters, numbers, and
hyphen-separated words.

Development branches use `develop` as their base and pull requests target
`develop`. Supported types are `feature`, `bugfix`, `hotfix`, `chore`,
`refactor`, `docs`, and `spike`. Hotfix branches start from `main`, the
production branch, and their pull requests target `main`. After a hotfix is
merged and verified on `main`, forward-port it to `develop` if needed.
Descriptions may contain uppercase or lowercase letters and numbers, separated
by single hyphens; spaces, underscores, and consecutive hyphens are not allowed.
Ticket IDs may only be used by one branch in this repository; the script checks
both local and remote branches before creating one.

On pull requests, a secondary advisory check warns if the branch name or PR
target does not follow these conventions; it does not block merging. No branch
naming check runs on pushes.
