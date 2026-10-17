# Evaluation-only checks standing in for downstream flakes that use dots by file
# path instead of through the host constructors. dots cannot see such consumers,
# so these reproduce how one actually does it (modelled on a real downstream
# flake): the shell and nvim modules imported by path, and a vscode module of its
# own that builds profiles from dots' individual feature files, `groups.nix`,
# `lib.nix`, `keybindings.nix` and `settings/global`, never importing dots'
# `modules/home/vscode/default.nix`.
#
# Only the derivation path is computed (written to a file, nothing is built), so
# `nix flake check` stays cheap.
{inputs}: let
  system = "x86_64-linux";
  dots = inputs.self;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [inputs.nix-vscode-extensions.overlays.default];
    config.allowUnfree = true;
  };

  base = {
    home.username = "consumer";
    home.homeDirectory = "/home/consumer";
    home.stateVersion = "25.11";
  };

  # A downstream vscode module: deep imports of dots' files, own list of profiles.
  vscodeModule = {
    pkgs,
    config,
    lib,
    ...
  }: let
    dotsVscode = "${dots}/modules/home/vscode";
    globalSettings = import "${dotsVscode}/settings/global";
    globalKeybindings = import "${dotsVscode}/keybindings.nix";
    vscodeLib = import "${dotsVscode}/lib.nix" {inherit lib globalSettings globalKeybindings;};
    features =
      builtins.mapAttrs (_: path: import path {inherit pkgs config;})
      (lib.genAttrs [
          "nix"
          "git"
          "markdown"
          "better-comments"
          "toml"
          "json"
          "kdl"
          "theme"
          "utils"
          "claude"
          "latex"
          "java"
          "python"
          "vsrocq"
          "haskell"
          "ocaml"
          "disable-breakpoint"
          "unicode-math-symbols"
        ]
        (name: "${dotsVscode}/features/${name}.nix"));
    groups = import "${dotsVscode}/groups.nix" {inherit features;};
  in {
    imports = ["${dotsVscode}/profile-ui-state.nix"];
    programs.vscode = {
      enable = true;
      mutableExtensionsDir = false;
      profiles = {
        default = (vscodeLib.mkProfile groups.default).profile;
        java = (vscodeLib.mkProfile groups.java).profile;
        python = (vscodeLib.mkProfile groups.python).profile;
        rocq = (vscodeLib.mkProfile groups.rocq).profile;
        haskell = (vscodeLib.mkProfile groups.haskell).profile;
      };
    };
  };

  consumer = modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inputs = inputs // {inherit dots;};};
      modules = [base] ++ modules;
    }).activationPackage.drvPath;

  check = name: modules:
    pkgs.writeText name (builtins.unsafeDiscardStringContext (consumer modules));
in {
  # shell + nvim by path, plus the vscode module above: the full downstream shape.
  consumer-full = check "consumer-full-evaluates" [
    "${dots}/modules/home/shell"
    "${dots}/modules/home/nvim"
    vscodeModule
  ];
  # The vscode module alone. It must not rely on another dots module (nvim, say)
  # happening to declare an option its feature files read.
  consumer-vscode-only = check "consumer-vscode-only-evaluates" [vscodeModule];
}
