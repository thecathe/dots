{
  description = "A non-NixOS machine's home-manager configuration, built on dots";

  inputs = {
    # The shared configuration, and with it every version pin (nixpkgs,
    # home-manager, ...). Bump deliberately with `nix flake update dots`.
    dots.url = "github:thecathe/dots";

    # Follows dots' nixpkgs. Nothing here uses it directly; it lets tools such
    # as nixd take nixpkgs from this flake.
    nixpkgs.follows = "dots/nixpkgs";
  };

  outputs = {dots, ...}: {
    # Apply with: home-manager switch --flake .#NEW_USER@NEW_HOST
    # (the first time: nix run home-manager/master -- switch --flake .#NEW_USER@NEW_HOST)
    homeConfigurations."NEW_USER@NEW_HOST" = dots.lib.mkHome {
      modules = [./home.nix];
    };
  };
}
