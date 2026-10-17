{ pkgs, config, ... }:
let
  inherit (pkgs) lib;
  cfg = config.dots.nixd;
  # Option completion needs the flake that defines the hosts (see modules/home/nixd.nix).
  hostOptions =
    lib.optionalAttrs (cfg.flake != null && cfg.nixosHost != null) {
      "nixos" = {
        "expr" = "(builtins.getFlake \"${cfg.flake}\").nixosConfigurations.${cfg.nixosHost}.options";
      };
    }
    // lib.optionalAttrs (cfg.flake != null && cfg.homeConfiguration != null) {
      "home_manager" = {
        "expr" = "(builtins.getFlake \"${cfg.flake}\").homeConfigurations.\"${cfg.homeConfiguration}\".options";
      };
    };
in
{
  extensions = with pkgs.vscode-extensions; [
    bbenoist.nix
    b4dm4n.vscode-nixpkgs-fmt
    kamadorueda.alejandra
    jnoortheen.nix-ide
    jeff-hykin.better-nix-syntax
  ];
  settings = {
    "nix" = {
      "enableLanguageServer" = true;
      "serverPath" = "nixd";
      "serverSettings" = {
        "nixd" = {
          "nixpkgs" = {
            "expr" = "import <nixpkgs> {}";
          };
          "formatting" = {
            "command" = [
              "alejandra"
            ];
          };
          # builtins.getFlake fails on a symlinked path ("path is a symlink"), so
          # dots.nixd.flake must be the real repo path. It is set per host.
          "options" = hostOptions;
        };
      };
    };
    "workbench.settings.applyToAllProfiles" = [
      "nix.enableLanguageServer"
      "nix.serverPath"
      "nix.serverSettings"
    ];
  };
}
