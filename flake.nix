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

    # Minecraft server + client tooling (self-hosted, nixos host only).
    # Local path input for zero-friction iteration while developing it
    # alongside dots. Once pushed to GitHub, switch to:
    #   url = "github:thecathe/minecraft";
    #
    # `nixos-rebuild switch` does NOT refresh this input's flake.lock pin on
    # its own - a `path:` input's narHash gets locked just like any other,
    # and changes to the minecraft repo (e.g. a new mod added to its packwiz
    # pack) are silently invisible to dots builds until you explicitly run
    # `nix flake update minecraft` here. Learned the hard way: several
    # rounds of "successful" rebuilds/switches turned out to be rebuilding
    # the same frozen Sep-30 snapshot, so none of a session's mod additions
    # ever reached the live server despite every build reporting success.
    minecraft = {
      url = "/home/cathe/Documents/git/thecathe/minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-gaming
    nix-gaming.url = "github:fufexan/nix-gaming";

    # declarative disk partitioning (used by hosts installed via nixos-anywhere)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for non-nixos hosts
    nixgl.url = "github:nix-community/nixGL";

    # Pinned ahead of the main nixpkgs input specifically for a newer Firefox:
    # a migrated real profile (from Firefox 154.0.1) hit storage/IndexedDB
    # errors on Microsoft/Outlook sites when opened with the main input's
    # older 153.0.1 (see modules/home/firefox/default.nix). Drop this once
    # the main nixpkgs input catches up to >=154.0.1.
    nixpkgs-firefox.url = "github:nixos/nixpkgs/34ab99075ac4f7e40cf037eef32cb1c360bb85e9";

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
    disko,
    stylix,
    dms,
    dms-plugin-registry,
    nixgl,
    nix-vscode-extensions,
    minecraft,
    #    onto-nvim,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    unfreeAllowList = import ./modules/shared/unfree.nix;
    unfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfreeAllowList;
    # "minecraft-server": the Fabric server (minecraft flake input) builds on
    # the actual Mojang vanilla server jar, unlike Paper which is an
    # independently-licensed (GPL3) rebuild - see the minecraft repo's
    # modules/nixos/default.nix for details.
    unfreeAllowListNixOS = unfreeAllowList ++ ["nvidia-x11" "discord" "discord-unwrapped" "steam" "steam-unwrapped" "nvidia-settings" "minecraft-server"];
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

        minecraft.nixosModules.default
      ];
    };

    ###### nixos-laptop
    nixosConfigurations.nixos-laptop = inputs.nixpkgs.lib.nixosSystem {
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
        ./hosts/nixos-laptop
        inputs.disko.nixosModules.disko
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
            users.cathe = import ./hosts/nixos-laptop/home.nix;
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
      rocq = {
        path = ./templates/rocq;
        description = "Rocq (Coq) project with opam, dune and direnv, extending the OCaml template";
      };
      erlang = {
        path = ./templates/erlang;
        description = "Erlang/OTP project with rebar3 and direnv";
      };
      go = {
        path = ./templates/go;
        description = "Go project with gopls, gotools and direnv";
      };
      haskell = {
        path = ./templates/haskell;
        description = "Haskell project with cabal, GHC, haskell-language-server and direnv";
      };
      latex = {
        path = ./templates/latex;
        description = "LaTeX project with Tectonic and direnv";
      };
      latex-texlive = {
        path = ./templates/latex-texlive;
        description = "LaTeX project needing real texlive (packages outside Tectonic's bundle, LuaTeX, etc.) and direnv";
      };
      home-manager-user = {
        path = ./templates/home-manager-user;
        description = "Standalone home-manager flake for a new user on a shared NixOS host (e.g. nixos-laptop), independent of this repo's nixosConfigurations";
      };
    };
  };
}
