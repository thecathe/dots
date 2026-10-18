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

    # DankSearch (dsearch): the indexed filesystem search DMS's Spotlight
    # launcher uses for its Files tab / `/` prefix. Home-manager module only
    # (no nixosModule), wired alongside dms.homeModules below.
    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankCalendar (dcal): standalone calendar app + sync daemon (Local,
    # Google, Microsoft, CalDAV, iCloud) in DMS's design language. Has its
    # own home-manager module (programs.dank-calendar), wired below.
    dcal = {
      url = "github:AvengeMedia/dcal";
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

    # Forester VS Code setup (forest-keeper pin/patches, forester-edit
    # extension, keybindings, scripts, dev shell) around the ocaml-forester
    # fork. Pick up changes with `nix flake update vscode-forester`.
    vscode-forester = {
      url = "github:thecathe/vscode-forester";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  # dots defines no machines. Each host lives in its own flake (my own are in the
  # `hosts` repo) and consumes the constructors and module sets exported here,
  # reusing this flake's inputs so there is a single set of version pins.
  outputs = {...} @ inputs: let
    hostLib = import ./lib/hosts.nix {inherit inputs;};
    alejandra = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
  in {
    # Constructors for the wiring every host shares; a host supplies only what
    # is specific to it. See lib/hosts.nix.
    lib = {
      inherit (hostLib) mkNixos mkHome;
      # Font packages shared by every host: `dots.lib.fonts pkgs`.
      fonts = import ./modules/shared/fonts.nix;
    };

    # The shared module sets a host imports.
    homeModules.default = ./modules/home;
    nixosModules.default = ./modules/nixos;

    # `nix fmt` formats the repo with alejandra.
    formatter.x86_64-linux = alejandra;

    # dots cannot see what depends on it. These stand in for consumers; the real
    # test of the hosts is `check` in the hosts repo. `formatting` fails if any
    # .nix file is not alejandra-formatted (fix with `nix fmt`).
    checks.x86_64-linux =
      import ./checks/consumer.nix {inherit inputs;}
      // {
        formatting = inputs.nixpkgs.legacyPackages.x86_64-linux.runCommand "formatting" {} ''
          ${alejandra}/bin/alejandra --check --quiet ${inputs.self} && touch $out
        '';
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
      python = {
        path = ./templates/python;
        description = "Python project with uv, pyproject.toml, ruff and direnv";
      };
      java = {
        path = ./templates/java;
        description = "Java project with a plain JDK (javac), jdtls and direnv";
      };
      java-gradle = {
        path = ./templates/java-gradle;
        description = "Java project with Gradle (Kotlin DSL), JUnit 5, jdtls and direnv, extending the Java template";
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
