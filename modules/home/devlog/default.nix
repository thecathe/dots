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

  # Pull before a session writes anything, so two hosts rarely diverge. Pull
  # only: pushing is always the user's call (`dlsync --push`). Quiet on
  # success because a SessionStart hook's stdout is added to Claude's context;
  # on failure the stderr headline is shown to the user (never to Claude) as a
  # hook error. `startup|resume` skips /clear and compaction, which are
  # mid-session. The marker comment is how merge-hooks.jq recognises the hook
  # as dots' own.
  managed = lib.optionalAttrs (enabled && cfg.claudeHook) {
    SessionStart = [
      {
        matcher = "startup|resume";
        hooks = [
          {
            type = "command";
            command = "${lib.getExe dlsync} --quiet # dots:managed";
            timeout = 30;
          }
        ];
      }
    ];
  };
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
        as it was whenever it cannot. Null disables the feature.
      '';
    };
    claudeHook = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add a pull-only `dlsync` to Claude Code's SessionStart hooks (on startup
        and resume), merged into the mutable `~/.claude/settings.json` on every
        activation. Has no effect while `dir` is null.
      '';
    };
  };

  config = {
    home.packages = lib.optional enabled dlsync;

    # ~/.claude/settings.json is a mutable file that /config and /model write
    # (see ../claude), so the hook is merged into it rather than declared. This
    # runs even when the feature is off, to take a hook it once added back out;
    # it touches the file only if the hook is wanted or its marker is present.
    home.activation.dlsyncClaudeHook = lib.hm.dag.entryAfter ["claudeCodeSettings"] ''
      settings="$HOME/.claude/settings.json"
      if [ -e "$settings" ]; then
        file=$(readlink -f "$settings")
        if ${lib.boolToString (managed != {})} || ${pkgs.gnugrep}/bin/grep -q 'dots:managed' "$file"; then
          tmp=$(mktemp "$file.XXXXXX")
          if ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg (builtins.toJSON managed)} \
            -f ${./merge-hooks.jq} "$file" > "$tmp"; then
            if ${pkgs.diffutils}/bin/cmp -s "$tmp" "$file"; then
              rm -f "$tmp"
            else
              chmod --reference="$file" "$tmp"
              run mv "$tmp" "$file"
            fi
          else
            rm -f "$tmp"
            warnEcho "could not update the dlsync hook in $file (is it valid JSON?); left as it was"
          fi
        fi
      fi
    '';
  };
}
