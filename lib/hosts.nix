# Host constructors: the wiring every host repeats (home-manager, the unfree
# allow-list, the vscode-extensions overlay). A host supplies only what is
# specific to it, so a host definition can live outside this repo and consume it
# as `dots.lib.mkNixos` / `dots.lib.mkHome`.
#
# The upstream modules dots' own module sets need (DankMaterialShell, stylix,
# ...) are imported by those sets (flake.nix), not here, so the sets also work
# in a plain configuration. Moving them there reordered some lists (the
# packages in home-manager-path) and nothing else.
{inputs}: let
  inherit (inputs) nixpkgs home-manager;
  system = "x86_64-linux";

  unfreeAllowList = import ../modules/shared/unfree.nix;
  mkUnfreePredicate = extra: pkg: builtins.elem (nixpkgs.lib.getName pkg) (unfreeAllowList ++ extra);

  overlays = [inputs.nix-vscode-extensions.overlays.default];

  # The `inputs` a host's modules receive: these inputs, `dots` itself (so a host
  # can import dots' modules wherever the host's own files happen to live), and
  # any inputs the host adds.
  withDots = extraInputs: inputs // {dots = inputs.self;} // extraInputs;
in {
  # A NixOS system with home-manager for one user.
  #   modules       host NixOS modules, placed before the shared stack
  #   modulesAfter  NixOS modules placed after it
  #   home          the user's home-manager module (a path)
  #   user          the user's login name (sets dots.user.name)
  #   unfreeExtra   unfree package names allowed on top of the shared list
  #   extraInputs   extra flake inputs, merged into the `inputs` modules receive
  mkNixos = {
    modules,
    home,
    user,
    modulesAfter ? [],
    unfreeExtra ? [],
    extraInputs ? {},
  }: let
    inputs' = withDots extraInputs;
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inputs = inputs';};
      modules =
        [
          {
            dots.user.name = user;
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
            nixpkgs = {
              config.allowUnfreePredicate = mkUnfreePredicate unfreeExtra;
              inherit overlays;
            };
          }
        ]
        ++ modules
        ++ [
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inputs = inputs';};
              users.${user} = import home;
            };
          }
        ]
        ++ modulesAfter;
    };

  # A standalone home-manager configuration (non-NixOS host).
  #   modules       the host's home-manager modules, placed before the shared ones
  #   unfreeExtra / extraInputs  as for mkNixos
  mkHome = {
    modules,
    unfreeExtra ? [],
    extraInputs ? {},
  }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfreePredicate = mkUnfreePredicate unfreeExtra;
      };
      extraSpecialArgs = {inputs = withDots extraInputs;};
      modules =
        modules
        ++ [
          # On NixOS stylix's own module brings this in; see flake.nix.
          inputs.stylix.homeModules.stylix
        ];
    };
}
