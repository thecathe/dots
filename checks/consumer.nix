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
          "tab-groups"
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
  # The newer shape: dots' area modules (homeModules.shell/nvim/vscode), VS Code
  # with a few profiles, on a nixpkgs without the nix-vscode-extensions overlay
  # (the vscode module brings its own). Asserts that a profile set without
  # Erlang doesn't get Erlang on VS Code's PATH.
  modulesConsumer = let
    hm = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        base
        dots.homeModules.shell
        dots.homeModules.nvim
        dots.homeModules.vscode
        {
          dots.vscode = {
            enable = true;
            profiles = ["java" "python" "rocq" "haskell"];
          };
        }
      ];
    };
    vscode = hm.config.programs.vscode;
  in
    assert inputs.nixpkgs.lib.assertMsg (inputs.nixpkgs.lib.attrNames vscode.profiles == ["default" "haskell" "java" "python" "rocq"])
    "consumer-modules: unexpected profiles ${toString (inputs.nixpkgs.lib.attrNames vscode.profiles)}";
    assert inputs.nixpkgs.lib.assertMsg (hm.config.dots.vscode.extraPath == [])
    "consumer-modules: Erlang reached VS Code's PATH without an Erlang profile";
      hm.activationPackage.drvPath;

  # The globalprotect module imported by path on its own, as a second user would
  # (it is self-contained, so nothing else of dots' needs to come with it). Enabled
  # with a portal it evaluates; enabled without one it must be refused.
  globalprotectModule = "${dots}/modules/home/globalprotect";
  globalprotectConsumer = let
    noPortalEvaluates = (builtins.tryEval (consumer [globalprotectModule {dots.globalprotect.enable = true;}])).success;
  in
    assert inputs.nixpkgs.lib.assertMsg (!noPortalEvaluates)
    "consumer-globalprotect: enabling dots.globalprotect without a portal evaluated";
      check "consumer-globalprotect-evaluates" [
        globalprotectModule
        {
          dots.globalprotect = {
            enable = true;
            portal = "vpn.example.com";
          };
        }
      ];
in {
  # The globalprotect module alone, by path.
  consumer-globalprotect = globalprotectConsumer;
  # The area modules with dots.vscode, as a second user's flake uses them.
  consumer-modules = pkgs.writeText "consumer-modules-evaluates" (builtins.unsafeDiscardStringContext modulesConsumer);
  # shell + nvim by path, plus the vscode module above: the full downstream shape.
  consumer-full = check "consumer-full-evaluates" [
    "${dots}/modules/home/shell"
    "${dots}/modules/home/nvim"
    vscodeModule
  ];
  # The same without nvim: the shell module plus the vscode module. Nothing here may
  # rely on the nvim module happening to declare an option that others read.
  consumer-no-nvim = check "consumer-no-nvim-evaluates" [
    "${dots}/modules/home/shell"
    vscodeModule
  ];
}
