{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-gaming
    nix-gaming.url = "github:fufexan/nix-gaming";

    # stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-gaming,
      stylix,
      ...
    }@inputs:
    {
      ###### nixos machine
      nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
          ./hosts/nixos

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.cathe = import ./hosts/nixos/home.nix;
          }

        ];
      };

      ###### worklaptop (ubuntu)
      homeConfigurations."cathe@worklaptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs;};
        modules = [./hosts/worklaptop/home.nix ];
      };

      ###### project templates
      templates = {
        ocaml = {
          path = ./templates/ocaml;
          description = "OCaml project with opam, dune and direnv";
        };
        erlang = {
          path = ./templates/erlang;
          description = "Erlang/OTP project with rebar3 and direnv";
        };
        go = {
          path = ./templates/go;
          description = "Go project with gopls, gotools and direnv";
        };
      };

    };

}
