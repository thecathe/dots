{pkgs, ...}: {
  extensions = [pkgs.vscode-extensions.ocamllabs.ocaml-platform];
  settings = {
    "[ocaml]" = {
      "editor" = {
        "defaultFormatter" = "ocamllabs.ocaml-platform";
        "codeLens" = false;
      };
      "ocaml.sandbox" = {
        "kind" = "opam";
      };
    };

    # Paths the file watcher skips (added to VS Code's built-in .git/objects etc.).
    #
    # Why: the watcher is recursive, takes one inotify watch per directory, and
    # ignores .gitignore. All of a user's processes share one pool
    # (fs.inotify.max_user_watches: 65536 on worklaptop, from localsearch), and a
    # workspace that overdraws it fails with "Unable to watch for file changes"
    # (ENOSPC). Here, not in the global settings, so only the profiles that list
    # this feature (groups.nix) get it.
    #
    # Ranked by watches saved (directory counts measured on membranes, 2026-11-16;
    # share of the 65536 pool in brackets):
    "files.watcherExclude" = {
      # 1. HIGH, ~24.6k dirs [37%]. A project-local opam switch: the compiler plus
      #    the lib/doc/man tree of every installed package. Also churns heavily
      #    during `opam install`.
      "**/_opam/**" = true;
      # 2. HIGH, ~24.6k dirs [37%]. The dev shell's own opam root (flake.nix sets
      #    OPAMROOT=./.opam-root). ~24.5k of it is the opam-repository index,
      #    repo/default/packages/<pkg>/<pkg.version>. Since 2026-11-12; doubled the
      #    folder's watch cost, which tipped membranes over the limit.
      "**/.opam-root/**" = true;
      # 3. LOW in watches, 26-352 dirs across the five dune projects on worklaptop
      #    [<1% each], but HIGH in event noise: dune rewrites it on every build.
      #    The name is not dune-only (rebar3 and Mix also build into _build), so a
      #    profile without this feature, e.g. erlang, does not get it.
      "**/_build/**" = true;
    };
  };
  keybindings = [
    {
      key = "ctrl+shift+o";
      command = "ocaml.server.restart";
    }
  ];
}
