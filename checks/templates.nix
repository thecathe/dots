# Evaluation-only checks that the host templates still produce a working
# machine, so a change to dots' constructors or modules can't silently break
# them. Only derivation paths are computed; nothing is built.
{inputs}: let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  lib = inputs.nixpkgs.lib;
  hostLib = import ../lib/hosts.nix {inherit inputs;};

  check = name: drv:
    pkgs.writeText name (builtins.unsafeDiscardStringContext drv.drvPath);

  # A host built from a template gets kitty's terminfo entry in ~/.terminfo
  # (modules/home/terminfo.nix) without being told to. Without it, ssh from
  # kitty into the host garbles the line editor. `files` is the host user's
  # home.file.
  withKittyTerminfo = name: files:
    lib.throwIfNot
    (files ? ".terminfo" && lib.hasSuffix "-terminfo/share/terminfo" (toString files.".terminfo".source))
    "${name}: kitty's terminfo is not installed in ~/.terminfo";

  # On NixOS it is also in the system packages, which is what root sees
  # (modules/nixos/terminfo.nix); ~/.terminfo cannot reach root's own home.
  withSystemKittyTerminfo = name: packages:
    lib.throwIfNot
    (lib.any (p: let s = toString p; in lib.hasInfix "-kitty-" s && lib.hasSuffix "-terminfo" s) packages)
    "${name}: kitty's terminfo is not in the system packages, so root lacks it";

  # Stands in for the hardware-configuration.nix that nixos-generate-config
  # writes on the machine, which a template can't ship.
  hardware = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
  };

  hostNixos = hostLib.mkNixos {
    user = "NEW_USER";
    modules = [hardware ../templates/host-nixos/configuration.nix];
    home = ../templates/host-nixos/home.nix;
  };

  # The template's own flake.nix, called with this dots.
  hostHome = (import ../templates/host-home/flake.nix).outputs {dots = inputs.self;};
  hostHomeConfig = hostHome.homeConfigurations."NEW_USER@NEW_HOST";
in {
  template-host-nixos =
    withSystemKittyTerminfo "template-host-nixos" hostNixos.config.environment.systemPackages
    (withKittyTerminfo "template-host-nixos" hostNixos.config.home-manager.users.NEW_USER.home.file
      (check "template-host-nixos-evaluates" hostNixos.config.system.build.toplevel));

  template-host-home =
    withKittyTerminfo "template-host-home" hostHomeConfig.config.home.file
    (check "template-host-home-evaluates" hostHomeConfig.activationPackage);
}
