#!/usr/bin/env bash
# dots-snapshot DIR: a flake ref for the dots checkout DIR, at a commit of its current tracked state.
# Used by the `rebuild` alias (modules/home/rebuild, where the reasoning is) and by `check` (tools/check).
#
# `git stash create` sometimes exits 1 with nothing on stdout or stderr: the first call after a tracked file's
# timestamp or inode changed without its content changing (an editor or DMS saving a file, a touch), and the next
# call works. An empty result used to reach nix as `--override-input dots ''`, which nix reads as the current
# directory (the hosts flake itself) and then fails with "attribute 'lib' missing". So a failure is retried, loudly,
# and if it persists this exits non-zero with nothing on stdout, never an empty ref.
if [ -z "${1:-}" ]; then
  echo "usage: dots-snapshot DIR (a git checkout of dots)" >&2
  exit 2
fi
dir=$(realpath "$1") || exit 1
if ! git -C "$dir" rev-parse --git-dir >/dev/null; then
  echo "dots-snapshot: $dir is not a git checkout" >&2
  exit 1
fi

attempts=5
for ((attempt = 1; attempt <= attempts; attempt++)); do
  if rev=$(git -C "$dir" stash create); then
    # No output means nothing to stash (a clean tree): the snapshot is HEAD.
    [ -n "$rev" ] || rev=$(git -C "$dir" rev-parse HEAD) || exit 1
    if ((attempt > 1)); then
      echo "dots-snapshot: succeeded on attempt $attempt of $attempts" >&2
    fi
    echo "git+file://$dir?rev=$rev"
    exit 0
  else
    status=$?
  fi
  echo "dots-snapshot: 'git stash create' failed in $dir (exit $status, attempt $attempt of $attempts)" >&2
  if ((attempt < attempts)); then
    echo "dots-snapshot: retrying" >&2
    sleep 0.3
  fi
done

echo "dots-snapshot: giving up after $attempts attempts: is something rewriting files in $dir? (see: git -C $dir status)" >&2
exit 1
