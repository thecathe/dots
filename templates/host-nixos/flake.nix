{
  description = "A NixOS machine built on dots";

  inputs = {
    # The shared configuration, and with it every version pin (nixpkgs,
    # home-manager, ...). Bump deliberately with `nix flake update dots`.
    dots.url = "github:thecathe/dots";

    # Follows dots' nixpkgs. Nothing here uses it directly; it lets tools such
    # as nixd take nixpkgs from this flake.
    nixpkgs.follows = "dots/nixpkgs";
  };

  outputs = {dots, ...}: {
    # Apply with: sudo nixos-rebuild switch --flake .#NEW_HOST
    nixosConfigurations.NEW_HOST = dots.lib.mkNixos {
      user = "NEW_USER";
      modules = [
        # Generated on the machine, see README.md.
        ./hardware-configuration.nix
        ./configuration.nix
      ];
      home = ./home.nix;
    };
  };
}
