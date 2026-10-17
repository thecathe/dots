# Evaluation-only check for downstream flakes that import part of dots by file
# path instead of through the host constructors. dots cannot see such consumers,
# so this stands in for them: a minimal home-manager config importing just the
# shell and vscode modules, the way a user of this repo's modules might.
#
# It only evaluates the configuration (the derivation path is written to a file,
# nothing is built), so `nix flake check` stays cheap.
{inputs}: let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [inputs.nix-vscode-extensions.overlays.default];
    config.allowUnfree = true;
  };
  consumer = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {inputs = inputs // {dots = inputs.self;};};
    modules = [
      {
        home.username = "consumer";
        home.homeDirectory = "/home/consumer";
        home.stateVersion = "25.11";
      }
      "${inputs.self}/modules/home/shell"
      "${inputs.self}/modules/home/vscode"
    ];
  };
in
  pkgs.writeText "consumer-imports-evaluate" (builtins.unsafeDiscardStringContext consumer.activationPackage.drvPath)
