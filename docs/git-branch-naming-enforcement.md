# Git Branch Naming Enforcement: Options and Recommendation

Objective: when a developer attempts to create a branch with an invalid name, branch creation should fail immediately, before the branch exists. Branches that already exist stay usable.

## 1. Key finding

Git has no hook named `pre-branch`. `post-checkout`, `pre-push`, `pre-commit`, and `post-commit` run at other times. GitHub Actions and ordinary webhooks run after a triggering event. GitHub Rulesets can apply supported server-side restrictions, and on GitHub Free they are available for public repositories. A private repository on GitHub Free does not get rulesets or branch protection. Rulesets also do not apply an arbitrary naming regular expression on every creation path.

Git does provide `reference-transaction` (Git 2.28 and later). It runs while Git is still preparing a ref update. If the script exits with an error during the `prepared` state, Git aborts the transaction and the new branch is never written. The same abort happens during `preparing` on newer Git. This covers `git branch`, `git switch -c`, `git checkout -b`, and IDE actions that call Git.

The script in this repository rejects only a brand-new `refs/heads/` ref whose old value is all zeros and whose name breaks policy. Commits, pushes, deletions, and checkouts of branches that already exist continue. `main`, `develop`, and `iith` are allowed.

Practical conclusion: use `reference-transaction` for immediate local prevention of new invalid names. Keep `create-branch.sh` as the normal create command, because it also checks a clean working tree, the base branch, and ticket uniqueness. Keep the pull-request workflow as the GitHub check. `pre-commit`, `post-commit`, and Husky are not required for this policy.

A developer who controls the machine can remove the hook. `--no-verify` does not skip `reference-transaction`.

## 2. Available approaches

| Approach | When validation happens | Can prevent invalid local branch creation? | Notes / cost |
| --- | --- | --- | --- |
| Git hook: `reference-transaction` | While Git is preparing the new branch ref | Yes, for new branches | Free. Existing branches keep working. One `git config` per clone. |
| Git hook: `post-checkout` | After checkout or branch switch | No | Free. Can warn, but the branch already exists. |
| Git hook: `pre-push` | Before pushing to remote | No | Free. Can reject a push. A name check here would also block pushes of older branches. |
| Git hook: `pre-commit` | Before a commit is created | No | Free. Does not run at branch creation. A name check here would block commits on older branches. |
| Git hook: `post-commit` | After the commit is saved | No | Free. Can print a message only. |
| Husky | When a configured Git hook runs | Not directly | Free. Installs hooks such as `pre-commit` or `pre-push`. It adds no branch-creation event. |
| GitHub Actions | After a workflow trigger, for example `pull_request` | No | Free-tier minute limits apply. Can block merging when the check is required and the repository settings allow that. |
| GitHub Rulesets / branch protection | When GitHub evaluates a supported server-side operation | No | Public repositories on GitHub Free can use rulesets. Private repositories on GitHub Free cannot. Prefix rules are available. Full arbitrary regex should not be assumed. |
| GitHub App / webhook | Usually after a branch event | No, not reliably | Requires development and hosting. Deleting the branch afterward is not immediate prevention. |
| Custom Git command / `create-branch.sh` | Before that command invokes Git | Yes, when that command is used | Free. Also checks base branch, a clean tree, and ticket uniqueness. Direct Git commands bypass it unless `reference-transaction` is installed. |
| Self-hosted Git server with server-side hooks | Before accepting a remote ref update | Can reject invalid remote branch creation | Git software may be free. Hosting and administration take time. |
| IDE extension | During branch creation in that IDE | Potentially, in that IDE only | Depends on the extension. An IDE that calls Git is already covered by `reference-transaction`. |

## 3. Husky and the commit hooks

These are not part of the setup. `reference-transaction` already stops creation of a new branch with an invalid name.

Husky configures Git hooks for JavaScript and TypeScript repositories. It can run `pre-commit` or `pre-push`. It does not supply a hook that runs before `git switch -c` or `git checkout -b`. Installing Husky here would only be a way to set `core.hooksPath` during `npm install`. This repository does not need that.

| Hook | What it does |
| --- | --- |
| `post-checkout` | Runs after checkout or switch. The branch already exists. |
| `pre-push` | Runs before a push. It can reject the push. It does not stop local creation. |
| `pre-commit` | Runs before a commit. It does not run when a branch is created. |
| `post-commit` | Runs after the commit is saved. It cannot reject that commit or stop branch creation. |

## 4. GitHub Actions: second layer

In this repository, `.github/workflows/branch-name.yml` checks the pull request source branch and the pull request target. It reports an invalid name after the workflow starts. It also checks that a hotfix targets `main` and that other work targets `develop`. Those target rules are not known at the moment a local branch is created, so they stay in this workflow.

The hook checks the name only. The workflow remains the place that checks the pull request target.

On a public repository, the workflow can be a required check where the plan supports it. On a private repository using GitHub Free, rulesets and branch protection are unavailable, so the workflow still runs and shows failure, and GitHub will not block the merge through a ruleset.

1. The developer creates a branch.
2. `reference-transaction` rejects a new invalid name before the branch exists.
3. The developer pushes a valid branch.
4. The developer opens or updates a pull request.
5. GitHub Actions validates the source branch name and the expected target.
6. A failed required check blocks merging where the repository settings support that.

## 5. Local control: `reference-transaction`

This is the control that meets the objective for new branches. The files in this repository are:

- `scripts/validate-branch-name.sh` checks one branch name and exits 0 or 1.
- `scripts/hooks/reference-transaction` calls that script only for a brand-new `refs/heads/` ref.

Name rules, shared with the pull-request workflow:

- Allowed types: `feature`, `bugfix`, `hotfix`, `chore`, `refactor`, `docs`, `spike`.
- Shape: `<type>/<numeric-ticket-id>-<description>`.
- The description may contain letters, numbers, underscores, and single hyphens.
- The description must contain at least one letter or number and must be at most 20 characters.
- `main`, `develop`, and `iith` are allowed.

Each clone points Git at the hook once:

```bash
git config core.hooksPath scripts/hooks
```

That setting is local. It is not copied by `git clone`. After the `scripts` directory is committed and pulled, each developer runs the same command once.

Checks:

- `git switch -c wip-stuff` fails and leaves no branch.
- `git checkout -b wip-stuff` fails and leaves no branch.
- `git switch -c feature/142-po-approval` succeeds.
- A commit or checkout on a branch that already exists still works.

`create-branch.sh` stays the normal way to create a branch. It applies the name rules and also requires a clean working tree, the correct base (`develop`, or `main` for a hotfix), and a ticket id that is not already used by a local or remote branch.

## 6. Steps for a developer

1. Clone the repository and enter `demo-repository`.
2. Turn the hook on once for that clone:

```bash
git config core.hooksPath scripts/hooks
```

3. Commit or stash current edits. `create-branch.sh` runs when the working tree is clean.
4. Create the branch.

Development work, from `develop`:

```bash
./create-branch.sh feature 142 po-approval-workflow --base develop
```

A hotfix, from `main`:

```bash
./create-branch.sh hotfix 301 payment-rounding --base main
```

The hook also applies when the developer creates the branch with Git directly:

```bash
git switch -c feature/142-po-approval
```

```bash
git checkout -b feature/142-po-approval
```

Those two commands enforce the name. The script also enforces the base branch, a clean working tree, and one branch per ticket.

## 7. Limitations

- The hook files must be in the clone. Until they are committed and pushed, other developers do not have them.
- Every new clone needs `git config core.hooksPath scripts/hooks` once.
- A developer can turn the hook off by changing that setting or removing the script. `--no-verify` does not turn it off.
- The hook does not check which branch a future pull request will target. That stays in `branch-name.yml`.
- The hook does not check ticket uniqueness. That stays in `create-branch.sh`.
- On a private GitHub Free repository, skip rulesets. On a public repository, a later ruleset can include all branches, exclude `main`, `develop`, `iith`, and `feature/**`, `bugfix/**`, `hotfix/**`, `chore/**`, `refactor/**`, `docs/**`, `spike/**`, and enable **Restrict creations** only. That enforces prefixes. `feature/not-a-ticket` can still be created on GitHub. Leave **Restrict updates** off so existing branches can still be pushed.
- A self-hosted Git server with a server-side hook can reject the remote ref when the policy must hold for every user and tool, including clones that never installed the local hook.

## 8. Recommendation for DISHA

- Local prevention for new names: keep `scripts/hooks/reference-transaction` and `scripts/validate-branch-name.sh`.
- Normal create command: keep `create-branch.sh`.
- Pull-request safety net: keep `.github/workflows/branch-name.yml`.
- Do not add Husky, `pre-commit`, `post-commit`, `post-checkout`, or `pre-push` for this naming policy.
- After clone, each developer runs `git config core.hooksPath scripts/hooks` once.
- On GitHub Free, add a prefix ruleset only when the repository is public. Leave private free repositories on the local hook plus the pull-request workflow.

## 9. References

- Git hooks, including `reference-transaction`: https://git-scm.com/docs/githooks
- GitHub Rulesets overview: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- GitHub Ruleset rules and availability: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
- Husky documentation: https://github.com/typicode/husky/blob/main/docs/get-started.md
