{ pkgs, ... }:
let
  # pgourlain.erlang unconditionally shells out to `rebar3 compile` on every
  # activation to build its own "Erlang bridge" (apps/erlangbridge), and
  # rebar.config's `{provider_hooks, [{pre, [{compile, clean}]}]}` runs
  # `clean` first, every single time. `clean` tries to delete the
  # pre-generated yecc parser output apps/erlangbridge/src/vscode_erlfmt_parse.erl
  # in place, which fails with EROFS once installed into a read-only Nix
  # store path, aborting the whole compile ("Erlang language server failed
  # to start: compiling the Erlang bridge with rebar3 failed").
  #
  # compileErlangBridge (out/lib/lsp/lspclientextension.js) only treats that
  # failure as *fatal* when no previous build exists -- it tolerates a
  # nonzero rebar3 exit as long as
  # _build/default/lib/vscode_lsp/ebin/vscode_lsp_entry.beam already exists
  # (erlangBridgePath, out/lib/erlangConnection.js). So: run the real
  # `rebar3 compile` once, here, at Nix build time, while $out is still
  # writable, and bake the resulting _build/ tree into the derivation.
  # rebar.config declares `{deps, []}`, so this is fully offline/reproducible.
  erlangExtWithBridge =
    pkgs.nix-vscode-extensions.vscode-marketplace-release-universal.pgourlain.erlang.overrideAttrs
      (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          pkgs.beamPackages.erlang
          pkgs.beamPackages.rebar3
        ];
        postInstall =
          (old.postInstall or "")
          + ''
            (
              cd "$out/$installPrefix"
              HOME="$TMPDIR" rebar3 compile
            )
            # rebar3 always creates convenience `include`/`priv` symlinks under
            # _build/default/lib/<app>/ pointing back to the app's own include/
            # priv dirs, even when the app (erlangbridge) has neither. Harmless
            # in a normal mutable build, but nixpkgs' fixupPhase fails the
            # whole build on any dangling symlink under $out, so drop them now
            # that the real compile above has already succeeded.
            find "$out/$installPrefix/_build" -xtype l -delete
            if [ ! -f "$out/$installPrefix/_build/default/lib/vscode_lsp/ebin/vscode_lsp_entry.beam" ]; then
              echo "pgourlain.erlang: rebar3 compile did not produce vscode_lsp_entry.beam -- the Nix-side Erlang bridge prebuild is broken" >&2
              exit 1
            fi
          '';
      });
in
{
  extensions =
    with pkgs.vscode-extensions;
    [ ]
    ++ (with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [
      # erlang-ls dropped: upstream archived/unmaintained since Aug 2025
      # (pointing users to ELP), and its bundled prebuilt escript crashes on
      # startup here (`application:ensure_all_started` failure inside
      # erlang_ls.erl) against this system's OTP 28 -- classic OTP-version
      # skew for an abandoned release, not something worth pinning an extra
      # Erlang version for. erlang-language-platform (ELP) already covers
      # its LSP functionality and is erlang-ls's own recommended successor.
      erlang-language-platform.erlang-language-platform
    ])
    ++ [ erlangExtWithBridge ];
  settings = {
    "[erlang]" = {
      # "editor.defaultFormatter" = "erlfmt";
      "editor.defaultFormatter" = "erlang-language-platform.erlang-language-platform";
    };
    "erlang.codeLensEnabled" = true;
    "elp" = {
      "hoverActions.enable" = true;
      "typesOnHover.enable" = true;
      "diagnostics.enableOtp" = true;
      "edoc.enable" = true;
      "lens.links.enable" = true;
    };
    "files.exclude" = {
      "**/*.beam" = true;
    };
  };
}
