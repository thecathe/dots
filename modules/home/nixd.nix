# Where nixd (the Nix language server, used by the vscode nix profile and by
# neovim) finds the options of the machines. dots defines no machines, so a host
# repo says where its flake is; with `flake` unset nixd just gets nixpkgs and
# there is no completion for NixOS / home-manager options.
{lib, ...}: {
  options.dots.nixd = {
    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/me/hosts";
      description = ''
        Path of the flake that defines the hosts. Use the real path, not a
        symlink: builtins.getFlake rejects symlinks. Its nixosConfigurations /
        homeConfigurations supply the options nixd completes, and its `nixpkgs`
        input supplies nixpkgs.
      '';
    };
    nixosHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "nixos";
      description = "Name of the nixosConfiguration whose options nixd completes.";
    };
    homeConfiguration = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "me@host";
      description = "Name of the homeConfiguration whose options nixd completes.";
    };
  };
}
