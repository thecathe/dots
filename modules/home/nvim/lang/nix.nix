{ lib, config, ... }:
let
  cfg = config.dots.nixd;
  # Option completion needs the flake that defines the hosts (see modules/home/nixd.nix).
  hostOptions =
    lib.optionalAttrs (cfg.flake != null && cfg.nixosHost != null) {
      nixos.expr = "(builtins.getFlake \"${cfg.flake}\").nixosConfigurations.${cfg.nixosHost}.options";
    }
    // lib.optionalAttrs (cfg.flake != null && cfg.homeConfiguration != null) {
      home_manager.expr = "(builtins.getFlake \"${cfg.flake}\").homeConfigurations.\"${cfg.homeConfiguration}\".options";
    };
  nixpkgsExpr =
    if cfg.flake != null then
      "(builtins.getFlake \"${cfg.flake}\").inputs.nixpkgs.legacyPackages.\${builtins.currentSystem}"
    else
      "import <nixpkgs> {}";
in
{
  # dots.nixd is declared here too so this works when imported on its own.
  imports = [ ../../nixd.nix ];
  xdg.configFile."nvim/lua/lang/nix.lua".text = builtins.replaceStrings
    [ "@@NIXPKGS_EXPR@@" "@@OPTIONS@@" ]
    [ nixpkgsExpr (lib.generators.toLua { } hostOptions) ]
    (builtins.readFile ./nix.lua);
  programs.neovim.initLua = lib.mkAfter "require('lang.nix')";
}
