# Welcome to your organization's demo respository
This code repository (or "repo") is designed to demonstrate the best GitHub has to offer with the least amount of noise.

The repo includes an `index.html` file (so it can render a web page), two GitHub Actions workflows, and a CSS stylesheet dependency.

## Branching

Create branches with `create-branch.sh`. Branch names use
`<type>/<numeric-ticket-id>-<short-description>`:

```bash
./create-branch.sh feature 142 po-approval-workflow --base develop
./create-branch.sh hotfix 301 payment-advice-rounding --base main
```

The `--base <branch>` argument is required. Development branches use `develop`
as their base and pull requests target
`develop`. Supported types are `feature`, `bugfix`, `hotfix`, `chore`,
`refactor`, `docs`, and `spike`. Hotfix branches start from `main`, the
production branch, and their pull requests target `main`. After a hotfix is
merged and verified on `main`, forward-port it to `develop` if needed.

Pull requests are checked for the branch-name format and the expected target;
make the `Validate branch name` check required in branch protection settings
for both `develop` and `main`.
