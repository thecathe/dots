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

    # snapd
    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-gaming
    nix-gaming.url = "github:fufexan/nix-gaming";

    # stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell (niri)
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # (dms) notification
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for non-nixos hosts
    nixgl.url = "github:nix-community/nixGL";

    # vscode extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## onto nvim plugin
    #   onto-nvim = {
    #     # url = "path:/home/cathe/Documents/git/thecathe/ontocaml";
    #     url = "github:thecathe/ontocaml";
    #     inputs.nixpkgs.follows = "nixpkgs";
    #   };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-snapd,
    nix-gaming,
    stylix,
    dms,
    dgop,
    dms-plugin-registry,
    nixgl,
    nix-vscode-extensions,
    #    onto-nvim,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    unfreeAllowList = import ./modules/shared/unfree.nix;
    unfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfreeAllowList;
    unfreeAllowListNixOS = unfreeAllowList ++ ["nvidia-x11" "discord" "steam" "steam-unwrapped" "nvidia-settings"];
    unfreePredicateNixOS = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfreeAllowListNixOS;
  in {
    ###### nixos machine
    nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        {
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          nixpkgs = {
            config.allowUnfreePredicate = unfreePredicateNixOS;
            overlays = [
              inputs.nix-vscode-extensions.overlays.default
            ];
          };
        }
        ./hosts/nixos
        inputs.stylix.nixosModules.stylix
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms-plugin-registry.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs;};
            sharedModules = [
              inputs.dms.homeModules.dank-material-shell
              inputs.dms-plugin-registry.homeModules.default
            ];
            users.cathe = import ./hosts/nixos/home.nix;
          };
        }

        nix-snapd.nixosModules.default
        {
          services.snap.enable = true;
        }
      ];
    };

    ###### worklaptop (ubuntu)
    homeConfigurations."cathe@worklaptop" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = unfreePredicate;
        overlays = [
          inputs.nix-vscode-extensions.overlays.default
        ];
      };
      extraSpecialArgs = {inherit inputs;};
      modules = [
        ./hosts/worklaptop/home.nix
        inputs.stylix.homeModules.stylix
        inputs.dms.homeModules.dank-material-shell
        inputs.dms-plugin-registry.homeModules.default
      ];
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
