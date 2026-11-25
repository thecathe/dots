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

    # nix-gaming. Deliberately NOT `inputs.nixpkgs.follows = "nixpkgs"`: the one
    # package taken from it, mo2installer (gaming profile), needs a Windows-target
    # gcc that does not evaluate on our nixos-unstable ("cannot coerce a set to a
    # string: { model = "win32"; ... }", tried 2026-11-22), so it builds with
    # nix-gaming's own nixpkgs. Its NixOS modules use the host's pkgs either way.
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
    optionsDoc = import ./lib/options-doc.nix {inherit inputs;};
    checkTool = import ./tools/check/package.nix {pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;};
    checkEachTool = import ./tools/check-each/package.nix {pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;};
    # dots' own inputs, as the `dotsInputs` module argument of both module sets, so a
    # module does not depend on what the importing flake calls its inputs (keyed, so
    # importing several sets is fine).
    dotsArgs = {
      key = "dots-args";
      _module.args.dotsInputs = inputs;
    };
  in {
    # Constructors for the wiring every host shares; a host supplies only what
    # is specific to it. See lib/hosts.nix.
    lib = {
      inherit (hostLib) mkNixos mkHome;
      # Font packages shared by every host: `dots.lib.fonts pkgs`.
      fonts = import ./modules/shared/fonts.nix;
    };

    # The module sets a host imports: `default` is everything, the others are
    # single areas for a flake that wants only those (e.g. a second user's own
    # config). Each carries dots' own inputs as the `dotsInputs` module
    # argument, so it doesn't depend on what the importing flake calls its
    # inputs (keyed, so importing several of them is fine).
    #
    # `default` and `nixosModules.default` import the upstream modules whose
    # options dots sets, so they work in a plain home-manager or NixOS
    # configuration and the constructors add nothing of the kind. They are
    # keyed, so a host that imports one twice gets it once. They cannot take
    # these from `dotsInputs`: that is a module argument, which `imports` may
    # not depend on.
    #
    # One exception: stylix's home-manager module. On NixOS, stylix's own NixOS
    # module imports it into every home-manager user (and copies the system's
    # theme into it), so importing it here as well would declare its options
    # twice. `mkHome` adds it for a standalone configuration, and
    # modules/home/stylix skips the theme, with a warning, where it is absent.
    homeModules = {
      default = {
        key = "dots-home";
        imports = [
          dotsArgs
          inputs.dms.homeModules.dank-material-shell
          inputs.dms-plugin-registry.homeModules.default
          inputs.danksearch.homeModules.default
          inputs.dcal.homeModules.default
          ./modules/home
        ];
      };
      vscode = {imports = [dotsArgs ./modules/home/vscode];};
      shell = {imports = [dotsArgs ./modules/home/shell];};
      nvim = {imports = [dotsArgs ./modules/home/nvim];};
      # apps
      flameshot = {imports = [dotsArgs ./modules/home/flameshot];};
      # Needs nothing from dots' inputs, hence no dotsArgs.
      globalprotect = {imports = [./modules/home/globalprotect];};
    };
    nixosModules.default = {
      key = "dots-nixos";
      imports = [
        dotsArgs
        inputs.stylix.nixosModules.stylix
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms-plugin-registry.nixosModules.default
        # nix-gaming's Wine and SteamOS-sysctl modules, which the gaming profile uses
        # (both inert until enabled). Its low-latency PipeWire module is not here.
        inputs.nix-gaming.nixosModules.wine
        inputs.nix-gaming.nixosModules.platformOptimizations
        ./modules/nixos
      ];
    };

    # `nix fmt` formats the repo with alejandra.
    formatter.x86_64-linux = alejandra;

    # The generated reference for the `dots.*` options (lib/options-doc.nix). The
    # GitHub Action in .github/workflows builds it on every push to `main` and
    # publishes the pages to the `options-reference` branch.
    packages.x86_64-linux = {
      options-reference = optionsDoc.reference;
      # Evaluates every machine of a flake that consumes dots, against a local dots
      # if given (tools/check/check.sh): `nix run github:thecathe/dots#check -- --help`.
      check = checkTool;
      # Runs every check of this flake in a process of its own under a memory ceiling,
      # one after another (tools/check-each/check-each.sh): `nix run .#check-each`.
      check-each = checkEachTool;
    };
    apps.x86_64-linux.check = {
      type = "app";
      program = "${checkTool}/bin/check";
      meta.description = "Evaluate every machine of a flake that consumes dots, optionally against a local dots";
    };
    apps.x86_64-linux.check-each = {
      type = "app";
      program = "${checkEachTool}/bin/check-each";
      meta.description = "Run every check of this flake one at a time, each in its own memory-capped process";
    };

    # dots cannot see what depends on it. These stand in for consumers; the real
    # test of the hosts is `check` in the hosts repo. `formatting` fails if any
    # .nix file is not alejandra-formatted (fix with `nix fmt`).
    #
    # `nix flake check` runs all of these inside one Nix process, whose memory is the
    # sum of the evaluations and outgrew 10 GiB on 2026-11-25. `nix run .#check-each`
    # runs the same checks one process at a time under a memory ceiling instead.
    checks.x86_64-linux =
      import ./checks/consumer.nix {inherit inputs;}
      // import ./checks/module-sets.nix {inherit inputs;}
      // import ./checks/templates.nix {inherit inputs;}
      // import ./checks/dlsync.nix {inherit inputs;}
      // import ./checks/orient.nix {inherit inputs;}
      // import ./checks/repos.nix {inherit inputs;}
      // import ./checks/niri-dms-outputs.nix {inherit inputs;}
      // import ./checks/flameshot-screen.nix {inherit inputs;}
      // import ./checks/check-each.nix {inherit inputs;}
      // import ./checks/options-reference.nix {inherit inputs optionsDoc;}
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
      host-nixos = {
        path = ./templates/host-nixos;
        description = "A NixOS machine built on dots (dots.lib.mkNixos), for a hosts repo";
      };
      host-home = {
        path = ./templates/host-home;
        description = "A non-NixOS machine's standalone home-manager config built on dots (dots.lib.mkHome), for a hosts repo";
      };
      kitty = {
        path = ./templates/kitty;
        description = "A kitty session (nvim above a shell) that opens in the project it is placed in";
      };
      home-manager-user = {
        path = ./templates/home-manager-user;
        description = "Standalone home-manager flake for a new user on a shared NixOS host (e.g. nixos-laptop), independent of this repo's nixosConfigurations";
      };
    };
  };
}
