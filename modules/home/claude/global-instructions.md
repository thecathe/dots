# Global Claude Code preferences

Managed declaratively from `modules/home/claude/global-instructions.md` in the dots repo and
deployed to `~/.claude/CLAUDE.md` by home-manager. Edit it there, not here.

A repository's own `CLAUDE.md`, where it has one, takes precedence over anything here where they
conflict. The author's repositories are meant to have none: what a session needs to know about a
repository comes from the `orient:` block (below), and a `note:` line in it is a rule of that
repository, followed like the rules in this file.
- Never add a `CLAUDE.md` to one of the author's repositories. A rule a session needs goes in that
  repository's `notes` in `registry.toml` (ask first, like any registry edit); a human contributor's
  build and layout notes go in its README.

## Start of a session
A SessionStart hook runs `orient`, which brings the devlog up to date and prints an `orient:` block
for the repository you are in: its devlog folder, how finished work is integrated, its
`dev/workbench`, its own rules (`note:` lines), and the effort the AI marker assumes. Take it as the
project's facts and rules. They are kept in `registry.toml` in the devlog
(`~/Documents/git/thecathe/devlog`), not in the project.
- If a line says the devlog is not in step, say so in your first reply.
- Before changing a project, read the `index.md` of its devlog folder (the block gives the path). If
  it is long, read the top and search it for the topic instead of reading it whole.
- With no `orient:` block (no hook on this host, or not a repository with an `origin`), use the
  defaults in this file: the devlog folder is the repository's name, and finished work is merged
  into `main` locally.

## Missing packages
If a command a task needs depends on a package that is not installed, do not assume it should be
installed for good. Ask the user to run it through a one-off shell:
`nix-shell -p PACKAGE --run "the-command --with args"`.

## Heavy Nix commands
A whole-flake evaluation (`nix flake check`, the hosts repo's `./check`, evaluating or building a
machine) can take more than 7 GB and has nearly run a laptop out of memory, freezing the desktop.
In the dots repository `nix flake check` is too big for any cap: it holds every check's evaluation
in one process and was killed by the kernel at 10 GiB. Never run it there; run the checks with
`nix run .#check-each` (in the dots checkout or worktree; `--help` lists the options) instead.
- `check-each` runs each check in a process of its own under a memory ceiling (6 GiB by default,
  no swap), one after another. Name checks to run only those; `--cap SIZE` sets the ceiling, and on
  the laptops (`worklaptop`, `nixos-laptop`) that is `--cap 3G`, which leaves the heaviest checks
  `KILLED`. A `KILLED` line means that check was NOT RUN (it hit the ceiling): it is neither a pass
  nor a failure, so report it as not run. Never raise the ceiling, or use `--no-cap`, on your own.
- For one change, prefer the checks scoped to it (`nix run .#check-each -- NAME...`, or
  `nix build .#checks.<system>.<name>` capped:
  `systemd-run --user --scope -p MemoryMax=3G -p MemorySwapMax=0 nice nix ... --max-jobs 1 --cores 2`).
  A run that hits the cap fails. Report it; never raise the cap or retry it uncapped on your own.
- Running all of the checks (`check-each` with no names), or anything without a cap, needs the
  author's explicit permission each time, especially on the laptops.

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
1. The project's `CLAUDE.md` names it, if it has one.
2. The `orient:` block names it (from `registry.toml`).
3. It is the branch currently checked out in the project's primary checkout,
   when that is a deliberate long-lived branch other than the default.
4. The repository's default branch (`main`).

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
- Nothing is pushed and no PR is opened unless the author asks. The one standing
  exception is `orient push-workbench`, below.
- A repository that is not the author's (the `orient:` block says "not yours")
  always goes by a PR on the remote, unless the block says its integration branch
  is pushed to `origin`. The author's own forks are theirs: no PR. Anything that
  goes upstream is a PR, and never assume that work on a fork touches upstream
  unless the author says so.
- The branch and method are facts about the repository, kept in `registry.toml`
  in the devlog, not in the project (a repository's own `CLAUDE.md`, if it still
  has one, wins). If neither the `orient:` block
  nor the repository settles them, ask the author the first time
  integration is needed, then record the answer in `registry.toml` (a devlog
  commit like any other).
- If the integration branch has moved by the time you are ready to merge, rebase
  your branch onto it first, then merge. Don't do this earlier merely because it
  moved while you were working.
- Never discard, reset, or overwrite the user's changes on the integration
  branch. If a conflict or ambiguity arises, stop and discuss it with the user.

### The workbench branch
- A project may keep your own tooling for it (test drivers, analysis scripts,
  helpers) on a long-lived branch `dev/workbench`, not on the integration branch.
  Its `dev/README.md` is the authority on using it: when the `orient:` block
  shows one, read that first (the block gives the command). Create one only after
  asking.
- Never merge it into the integration branch, and never merge the integration
  branch into it by hand: its README says who, if anyone, keeps it in step. By
  default it is a shelf, run from a checkout of its own, not a base that work
  branches start from; a project's README may say otherwise.
- `orient` fast-forwards it from `origin` at the start of a session. Commit your
  tooling to it freely.
- To share it between hosts, `orient push-workbench` pushes that one branch. It
  refuses unless the repository is the author's, private (checked live) and the
  push is a plain fast-forward, and it is the only push you may make without
  asking. Putting the branch on `origin` for the first time needs the author's
  explicit yes (`orient push-workbench --create`). A public repository's
  workbench stays local: ask before doing anything else with it.

### Approval
- Approval of a plan, or of any long-running autonomous task, covers merging the
  branch into the integration branch provided the work went as planned and agreed.
- If the outcome deviates meaningfully from the plan, or could have unintended
  side effects, get explicit approval from the user before merging.

## Design write-ups
- When a session's design work was interesting or insightful (trade-offs weighed,
  approaches rejected, surprising findings), record it, however little got built.
- Logs live outside the project they describe, in the shared `devlog` repo
  (`~/Documents/git/thecathe/devlog`), one folder per project. The `orient:` block
  names the project's folder (by default the repository's name; `registry.toml`
  holds the exceptions), or the project's `CLAUDE.md` does, if it has one. If there is none, ask
  before starting one, and record the answer in `registry.toml`.
- The devlog is private, but a redacted view of it is published. Before writing or
  editing any page there, from any project, read `publishing.md` at the devlog's root:
  it says what to leave out (other people's names, handles and repositories, work
  logins, addresses, secrets) and how to keep a private detail in a `<!-- private -->`
  block.
- A project's folder is laid out as:
  - `index.md`: the single point of entry and table of contents. Its table of
    feature entries is generated from each entry's `entry:` front matter (status,
    a short note of what is pending, dates, repos, summary) by `bin/devlog index`;
    never edit the table by hand. Small fixes and tweaks are bullets there of at
    most three lines (date, what, the commit); a small change gets no file of its
    own, and anything longer is an entry.
  - One `<feature>.md` per mini-project of adequate scope (a feature, a subsystem,
    or a design thread worth a session or more), not per session. It tells the
    story: the original vision, how and why the plan changed, and the final
    outcome. Record dates, context, decisions and why, alternatives considered,
    open questions, and the commits (with the repo each belongs to). Start one
    with `bin/devlog new`.
  - Returning to a topic updates its entry rather than starting a second one:
    its story, and its `entry:` block (`status`, `note`, `last`), then run
    `bin/devlog index`, in the same commit.
  - Before committing there, run `nix develop -c bin/devlog check`. The format
    and the statuses are in `publishing.md`, "Entries, their front matter, and
    the generated indexes".
- The repo's root `index.md` lists the projects and links each project's `index.md`.
- A project that already keeps its own log in-repo (e.g. `DEVELOPMENT.md`,
  `ASSISTED-CHANGES.md`) keeps using it until the user chooses to migrate it. Don't
  split or move it unprompted.
- When returning to a project after a gap, offer once to revisit its past entries
  (start from its `index.md`): what held up, and what could be improved or iterated on.

## AI-generated published content
- Any page Claude writes or substantially edits for a published site is explicitly
  marked as AI-generated, using the project's marker convention if it has one.
  The marker records the model, the effort level (or "unrecorded"), the date first
  generated, and the date last edited.
- The effort is what the `orient:` block's "AI-marker effort" line says for your
  model (set once in `registry.toml`). For a model it does not list, ask the
  author or write "unrecorded"; do not assume.
