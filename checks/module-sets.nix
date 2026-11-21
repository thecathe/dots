# The exported module sets, `homeModules.default` and `nixosModules.default`,
# imported into a plain configuration: a bare `homeManagerConfiguration` and a
# bare `nixosSystem`, none of the constructors in lib/hosts.nix, and no upstream
# module added by hand. The README says "a host imports dots.homeModules.default";
# this is what proves that sentence. Before the sets imported the upstream
# modules whose options they set (DankMaterialShell, its plugin registry,
# DankSearch, DankCalendar, stylix) it was true only through `mkNixos` and
# `mkHome`, and nothing noticed, because every host used them.
#
# Only derivation paths are computed (written to a file, nothing is built), so
# `nix flake check` stays cheap.
{inputs}: let
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
  dots = inputs.self;

  # No overlays: nothing here may depend on what a constructor adds to pkgs.
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  base = {
    home.username = "consumer";
    home.homeDirectory = "/home/consumer";
    home.stateVersion = "25.11";
  };

  home = modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [base] ++ modules;
    }).config;

  homeDrv = modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [base] ++ modules;
    }).activationPackage.drvPath;

  nixos = modules:
    lib.nixosSystem {
      inherit system;
      modules =
        [
          {
            dots.user.name = "consumer";
            nixpkgs.config.allowUnfree = true;
            system.stateVersion = "25.11";
            fileSystems."/" = {
              device = "/dev/disk/by-label/nixos";
              fsType = "ext4";
            };
            boot.loader.grub.enable = false;
          }
        ]
        ++ modules;
    };

  alone = home [dots.homeModules.default];
  twice = home [dots.homeModules.default dots.homeModules.default];
  withAreas = home [dots.homeModules.default dots.homeModules.shell dots.homeModules.vscode];
  nixosAlone = nixos [dots.nixosModules.default];
  nixosTwice = nixos [dots.nixosModules.default dots.nixosModules.default];

  # Named so that the failing assert says which one it was.
  written = name: text: assertion:
    lib.assertMsg assertion "module-sets-${name}: ${text}";
in {
  module-sets-home = assert written "home" "DankMaterialShell is not enabled by dots.homeModules.default" alone.programs.dank-material-shell.enable;
  assert written "home" "the DMS plugins dots installs are not there" (alone.programs.dank-material-shell.plugins ? dotsServices);
  assert written "home" "dots' option declarations were lost when the set was imported twice" (twice.dots.user.name == "consumer");
  assert written "home" "importing the set together with the area modules fails or loses the VS Code option" (withAreas.dots.vscode.enable);
    pkgs.writeText "module-sets-home-evaluates" (builtins.unsafeDiscardStringContext (
      homeDrv [dots.homeModules.default]
      + homeDrv [dots.homeModules.default dots.homeModules.default]
      + homeDrv [dots.homeModules.default dots.homeModules.shell dots.homeModules.vscode]
    ));

  module-sets-nixos = assert written "nixos" "stylix is not enabled by dots.nixosModules.default" nixosAlone.config.stylix.enable;
  assert written "nixos" "importing the set twice changes the system" (nixosTwice.config.stylix.enable);
    pkgs.writeText "module-sets-nixos-evaluates" (builtins.unsafeDiscardStringContext (
      nixosAlone.config.system.build.toplevel.drvPath + nixosTwice.config.system.build.toplevel.drvPath
    ));
}
