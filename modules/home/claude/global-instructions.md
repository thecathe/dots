# Global Claude Code preferences

Managed declaratively from `modules/home/claude/global-instructions.md` in the dots repo and
deployed to `~/.claude/CLAUDE.md` by home-manager. Edit it there, not here.

A project's own `CLAUDE.md` takes precedence over anything here where they conflict.

## Git workflow

### Commits
- Every commit message describes the change: `type(scope): summary`, with a
  body when the "why" isn't obvious from the summary. Omit `(scope)` when no
  sensible scope exists.
- One logical change per commit. Never mix unrelated changes in a commit.

### Integration branch
The integration branch is the long-lived branch that finished work is merged
into. It is usually `main`, but not always (e.g. a fork that works from a
customisation branch). Resolve it in this order:
1. The project's `CLAUDE.md` names it.
2. It is the branch currently checked out in the project's primary checkout,
   when that is a deliberate long-lived branch other than the default.
3. The repository's default branch (`main`).

Never infer it from upstream-tracking config: a local branch may track a
differently named remote branch (e.g. `cathe-customizations` tracking `origin/main`).

These rules never override a project's established practices. If a project works
from a branch other than `main`, keep using it: never switch the checkout to
`main`, never merge into or rebase onto `main`, and never reset or move the
standing branch. When the project's practice is unclear, ask before acting.

### Branches and isolation
- In a git-tracked project, do all work on a descriptively named local branch
  prefixed with the commit type (`feat/…`, `fix/…`, `chore/…`), never directly on
  the integration branch. This keeps its history readable as a sequence of scoped
  features and tweaks, with each branch acting as a chapter that can be explored
  individually.
- Work in a separate git worktree so the user's checkout of the integration
  branch is never disturbed. Remove the worktree (and delete the merged branch)
  as soon as it is no longer needed.
- Commit freely on the branch; it has no effect on the integration branch until
  merged.
- Don't push, open a PR, or merge until the user has clearly agreed to what is
  being done (see "Approval" below).
- Exceptions: single-line changes may be committed directly to the integration
  branch, even if they alter behaviour. Read-only tasks need no branch.

### Integrating into the integration branch
- Default method: `git merge --no-ff <branch>`, which preserves the branch
  history. Never squash.
- The branch and method are per-project settings. If the project's `CLAUDE.md`
  doesn't state them, ask the user for their preference the first time
  integration is needed (e.g. local `--no-ff` merge, or a pushed GitHub PR), then
  record the answer, including the integration branch, in the project's `CLAUDE.md`.
- If the integration branch has moved by the time you are ready to merge, rebase
  your branch onto it first, then merge. Don't do this earlier merely because it
  moved while you were working.
- Never discard, reset, or overwrite the user's changes on the integration
  branch. If a conflict or ambiguity arises, stop and discuss it with the user.

### Approval
- Approval of a plan, or of any long-running autonomous task, covers merging the
  branch into the integration branch provided the work went as planned and agreed.
- If the outcome deviates meaningfully from the plan, or could have unintended
  side effects, get explicit approval from the user before merging.
