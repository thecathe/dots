{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.devlog;
  enabled = cfg.dir != null;

  dlsync = import ./package.nix {
    inherit pkgs;
    defaultDir = cfg.dir;
  };
  # orient syncs the devlog through dlsync and reads registry.toml from the same
  # clone, so it needs no path option of its own.
  orient = import ./orient-package.nix {
    inherit pkgs;
    devlogDir =
      if enabled
      then cfg.dir
      else "";
  };

  # At the start of a session, orient pulls the devlog (so two hosts rarely
  # diverge) and prints what the session should know about its repository (see
  # orient.sh). Pull only: pushing is always the user's call (`dlsync --push`).
  # `--hook` keeps the exit status at 0 whatever happens: a SessionStart hook's
  # stdout is added to Claude's context only on exit 0, and a failed sync is
  # then reported as hook JSON (shown to the user, and in the context) instead of
  # as a non-zero exit that would also drop the preamble. The timeout covers
  # dlsync's own (a 20 s lock wait and a 30 s fetch) plus the workbench fetch.
  # `startup|resume` skips /clear and compaction, which are mid-session. The
  # marker comment is how merge-hooks.jq recognises the hook as dots' own.
  managed = lib.optionalAttrs (enabled && cfg.claudeHook) {
    SessionStart = [
      {
        matcher = "startup|resume";
        hooks = [
          {
            type = "command";
            command = "${lib.getExe orient} --hook # dots:managed";
            timeout = 60;
          }
        ];
      }
    ];
  };

  # The one push a session may make without asking: orient's guarded push of
  # dev/workbench (a rule per command line, with no arguments: `--create` is the
  # author's explicit yes and is deliberately not covered). The rule is written
  # with the bare command name, as a session types it, so it does not change
  # with every store path. `allowKnown` lists every rule this module has ever
  # managed, which is how merge-hooks.jq knows which to take out again.
  allow = lib.optional (enabled && cfg.claudeHook) "Bash(orient push-workbench)";
  allowKnown = ["Bash(orient push-workbench)"];
in {
  options.dots.devlog = {
    dir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/me/Documents/git/me/devlog";
      description = ''
        This host's clone of the shared devlog repo. Setting it installs `dlsync`,
        which fetches origin and fast-forwards or merges `main` into the clone
        (`dlsync --push` then publishes it), failing loudly with the clone left
        as it was whenever it cannot; and `orient`, which runs `dlsync`, reads
        `registry.toml` in the clone and tells a session about its repository.
        Null disables the feature.
      '';
    };
    claudeHook = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add `orient --hook` (a pull-only `dlsync` and the start-of-session
        preamble) to Claude Code's SessionStart hooks (on startup and resume),
        and allow the one command `orient push-workbench` without a prompt. Both
        are merged into the mutable `~/.claude/settings.json` on every
        activation. Has no effect while `dir` is null.
      '';
    };
  };

  config = {
    home.packages = lib.optionals enabled [dlsync orient];

    # ~/.claude/settings.json is a mutable file that /config and /model write
    # (see ../claude), so the hook and the permission are merged into it rather
    # than declared. This runs even when the feature is off, to take what it once
    # added back out; it touches the file only if something is wanted or a
    # trace of it is present (the hook's marker, or the permission rule).
    home.activation.orientClaudeHook = lib.hm.dag.entryAfter ["claudeCodeSettings"] ''
      settings="$HOME/.claude/settings.json"
      if [ -e "$settings" ]; then
        file=$(readlink -f "$settings")
        if ${lib.boolToString (managed != {})} || ${pkgs.gnugrep}/bin/grep -q -e 'dots:managed' -e 'orient push-workbench' "$file"; then
          tmp=$(mktemp "$file.XXXXXX")
          if ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg (builtins.toJSON managed)} \
            --argjson allow ${lib.escapeShellArg (builtins.toJSON allow)} \
            --argjson allowKnown ${lib.escapeShellArg (builtins.toJSON allowKnown)} \
            -f ${./merge-hooks.jq} "$file" > "$tmp"; then
            if ${pkgs.diffutils}/bin/cmp -s "$tmp" "$file"; then
              rm -f "$tmp"
            else
              chmod --reference="$file" "$tmp"
              run mv "$tmp" "$file"
            fi
          else
            rm -f "$tmp"
            warnEcho "could not update the orient hook in $file (is it valid JSON?); left as it was"
          fi
        fi
      fi
    '';
  };
}
