{pkgs, ...}: {
  # ELP finds a project by running `erl` and `rebar3`, and refuses to start
  # when either is missing from PATH. The vscode wrapper puts these on PATH
  # only when a profile with this feature is enabled (extraPath in
  # ../default.nix); a project's devShell normally provides them too.
  extraPath = [pkgs.beamPackages.erlang pkgs.beamPackages.rebar3];

  extensions = with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [
    # erlang-ls dropped: upstream archived/unmaintained since Aug 2025
    # (pointing users to ELP), and its bundled prebuilt escript crashes on
    # startup here (`application:ensure_all_started` failure inside
    # erlang_ls.erl) against this system's OTP 28 -- classic OTP-version
    # skew for an abandoned release, not something worth pinning an extra
    # Erlang version for. erlang-language-platform (ELP) already covers
    # its LSP functionality and is erlang-ls's own recommended successor.
    #
    # pgourlain.erlang dropped (2026-11-13), for now: it registers the same
    # `erlang` language and grammar as ELP, and its code-action handler
    # crashed (`lists:last([])` in find_closing_bracket_before_dot) on a
    # module whose `-file(...)` attribute comes before its first `-export`,
    # which VS Code reports as a failed request when such a file is opened.
    # What goes with it: its rebar3 tasks and commands, the debugger and the
    # snippets. To bring it back, revert the commit that removed it: that
    # commit also carries the derivation that prebuilds its Erlang bridge at
    # Nix build time, which is needed because the extension tries to
    # `rebar3 compile` inside the read-only store.
    erlang-language-platform.erlang-language-platform
  ];
  settings = {
    "[erlang]" = {
      # "editor.defaultFormatter" = "erlfmt";
      "editor.defaultFormatter" = "erlang-language-platform.erlang-language-platform";
    };
    # Run `elp` from PATH instead of the server the extension bundles. The
    # marketplace build ships a macOS (Mach-O) bin/elp, which cannot execute
    # on Linux ("cannot execute binary file"), and an empty serverPath makes
    # the extension launch exactly that. A project's devShell provides `elp`,
    # put on the extension host's PATH by mkhl.direnv.
    #
    # Set here, in user settings, not just in a project's .vscode/settings.json:
    # the setting is window-scoped, which a multi-root workspace (any
    # *.code-workspace with several folders) does not read from a folder's
    # .vscode/settings.json.
    "elp.serverPath" = "elp";
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
