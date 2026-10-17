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

## Design write-ups
- When a session's design work was interesting or insightful (trade-offs weighed,
  approaches rejected, surprising findings), record it, however little got built.
- Logs live outside the project they describe, in the shared `devlog` repo
  (`~/Documents/git/thecathe/devlog`), one folder per project. The project's
  `CLAUDE.md` names its folder; if it doesn't, ask the first time and record the
  answer there.
- A project's folder is laid out as:
  - `index.md`: the single point of entry and table of contents. It links every
    feature entry (title, date, status, one-line summary) and holds one-line
    entries for small fixes and tweaks directly. A small change gets no file of
    its own.
  - One `<feature>.md` per mini-project of adequate scope (a feature, a subsystem,
    or a design thread worth a session or more), not per session. It tells the
    story: the original vision, how and why the plan changed, and the final
    outcome. Record dates, context, decisions and why, alternatives considered,
    open questions, and the commits (with the repo each belongs to).
  - Returning to a topic updates its entry rather than starting a second one.
    Add or update the `index.md` line in the same commit.
- The repo's root `index.md` lists the projects and links each project's `index.md`.
- A project that already keeps its own log in-repo (e.g. `DEVELOPMENT.md`,
  `ASSISTED-CHANGES.md`) keeps using it until the user chooses to migrate it. Don't
  split or move it unprompted.
- When returning to a project after a gap, or at the end of a substantial session,
  offer once to revisit its past entries (start from its `index.md`): what held up,
  and what could be improved or iterated on.

## AI-generated published content
- Any page Claude writes or substantially edits for a published site is explicitly
  marked as AI-generated, using the project's marker convention if it has one.
  The marker records the model, the effort level (or "unrecorded"), the date first
  generated, and the date last edited.
