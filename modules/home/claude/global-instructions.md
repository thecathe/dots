# Global Claude Code preferences

Managed declaratively from `modules/home/claude/global-instructions.md` in the dots repo and
deployed to `~/.claude/CLAUDE.md` by home-manager. Edit it there, not here.

## Git workflow

### Commits
- Every commit message describes the change: `type(scope): summary`, with a
  body when the "why" isn't obvious from the summary. Omit `(scope)` when no
  sensible scope exists.
- One logical change per commit. Never mix unrelated changes in a commit.

### Branches and isolation
- In a git-tracked project, do all work on a descriptively named local branch
  prefixed with the commit type (`feat/…`, `fix/…`, `chore/…`), never on `main`.
  This keeps `main` readable as a history of scoped features and tweaks, with
  each branch acting as a chapter that can be explored individually.
- Work in a separate git worktree so the user's checkout of `main` is never
  disturbed. Remove the worktree (and delete the merged branch) as soon as it is
  no longer needed.
- Commit freely on the branch; it has no effect on `main` until merged.
- Don't push, open a PR, or merge until the user has clearly agreed to what is
  being done (see "Approval" below).
- Exceptions: single-line changes may be committed directly to `main`, even if
  they alter behaviour. Read-only tasks need no branch.

### Integrating into `main`
- Default method: `git merge --no-ff <branch>` into `main`, which preserves the
  branch history. Never squash.
- The method is a per-project setting. If the project's `CLAUDE.md` doesn't
  state one, ask the user for their preference the first time integration is
  needed (e.g. local `--no-ff` merge, or a pushed GitHub PR), then record the
  answer in the project's `CLAUDE.md`.
- If `main` has moved by the time you are ready to merge, rebase the branch onto
  `main` first, then merge. Don't do this earlier merely because `main` moved
  while you were working.
- Never discard, reset, or overwrite the user's changes on `main`. If a conflict
  or ambiguity arises, stop and discuss it with the user.

### Approval
- Approval of a plan, or of any long-running autonomous task, covers merging the
  branch into `main` provided the work went as planned and agreed.
- If the outcome deviates meaningfully from the plan, or could have unintended
  side effects, get explicit approval from the user before merging.
