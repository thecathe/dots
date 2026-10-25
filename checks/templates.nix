# Evaluation-only checks that the host templates still produce a working
# machine, so a change to dots' constructors or modules can't silently break
# them. Only derivation paths are computed; nothing is built.
{inputs}: let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  hostLib = import ../lib/hosts.nix {inherit inputs;};

  check = name: drv:
    pkgs.writeText name (builtins.unsafeDiscardStringContext drv.drvPath);

  # Stands in for the hardware-configuration.nix that nixos-generate-config
  # writes on the machine, which a template can't ship.
  hardware = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };

  # The template's own flake.nix, called with this dots.
  hostHome = (import ../templates/host-home/flake.nix).outputs {dots = inputs.self;};
in {
  template-host-nixos =
    check "template-host-nixos-evaluates"
    (hostLib.mkNixos {
      user = "NEW_USER";
      modules = [hardware ../templates/host-nixos/configuration.nix];
      home = ../templates/host-nixos/home.nix;
    }).config.system.build.toplevel;

  template-host-home =
    check "template-host-home-evaluates"
    hostHome.homeConfigurations."NEW_USER@NEW_HOST".activationPackage;
}
