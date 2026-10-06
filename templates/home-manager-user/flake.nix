{
  description = "Standalone home-manager config for a new user";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
  in {
    # Rename this key to "<your-username>@<hostname>" and apply with:
    #   nix run home-manager/master -- switch --flake .#<your-username>@<hostname>
    homeConfigurations."NEW_USER@NEW_HOST" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {inherit system;};
      modules = [./home.nix];
    };
  };
}
