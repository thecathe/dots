{ pkgs, ... }:
{
  extensions = [ pkgs.vscode-extensions.ocamllabs.ocaml-platform ];
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
  };
  keybindings = [
    {
      key = "ctrl+shift+o";
      command = "ocaml.server.restart";
    }
  ];
}
