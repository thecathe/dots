{
  lib,
  pkgs,
  ...
}: let
  globalSettings = import ./settings/global;
  globalKeybindings = import ./keybindings.nix;
  vscodeLib = import ./lib.nix {inherit lib globalSettings globalKeybindings;};
  features = builtins.mapAttrs (_: path: import path {inherit pkgs;}) {
    nix = ./features/nix.nix;
    ocaml = ./features/ocaml.nix;
    erlang = ./features/erlang.nix;
    go = ./features/go.nix;
    python = ./features/python.nix;
    java = ./features/java.nix;
    sql = ./features/sql.nix;
    web = ./features/web.nix;
    ssh = ./features/ssh.nix;
    git = ./features/git.nix;
    json = ./features/json.nix;
    latex = ./features/latex.nix;
    vsrocq = ./features/vsrocq.nix;
    markdown = ./features/markdown.nix;
    languagetool = ./features/languagetool.nix;
    better-comments = ./features/better-comments.nix;
    disable-breakpoint = ./features/disable-breakpoint.nix;
    claude = ./features/claude.nix;
    theme = ./features/theme.nix;
    utils = ./features/utils.nix;
  };
  groups = import ./groups.nix {inherit features;};
  defaultProfile = vscodeLib.mkProfile (groups.default);
  # projects
  indimoProfile = vscodeLib.mkProfile (groups.indimo);
  mebiProfile = vscodeLib.mkProfile (groups.mebi);
  cloakamlProfile = vscodeLib.mkProfile (groups.cloakaml);
  webserverProfile = vscodeLib.mkProfile (groups.webserver);
  # languages
  latexProfile = vscodeLib.mkProfile (groups.latex);
  ocamlProfile = vscodeLib.mkProfile (groups.ocaml);
  pythonProfile = vscodeLib.mkProfile (groups.python);
  goProfile = vscodeLib.mkProfile (groups.go);
  erlangProfile = vscodeLib.mkProfile (groups.erlang);
  javaProfile = vscodeLib.mkProfile (groups.java);
  ### all extensions -- temp, waiting for upstream fix of profile extensions being respected
  allExtensions = lib.unique (
    defaultProfile.extensions
    ++ indimoProfile.extensions
    ++ mebiProfile.extensions
    ++ cloakamlProfile.extensions
    ++ webserverProfile.extensions
    ++ latexProfile.extensions
    ++ ocamlProfile.extensions
    ++ pythonProfile.extensions
    ++ goProfile.extensions
    ++ erlangProfile.extensions
    ++ javaProfile.extensions
  );
in {
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = allExtensions;
    profiles = {
      # must set icons manually in vscode
      default = defaultProfile.profile;
      "indimo" = indimoProfile.profile;
      "mebi" = mebiProfile.profile;
      "cloakaml" = cloakamlProfile.profile;
      "webserver" = webserverProfile.profile;
      "ocaml" = ocamlProfile.profile;
      "latex" = latexProfile.profile;
      "python" = pythonProfile.profile;
      "go" = goProfile.profile;
      "erlang" = erlangProfile.profile;
      "java" = javaProfile.profile;
    };
  };
}
