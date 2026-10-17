# Host constructors: the wiring every host repeats (stylix, DankMaterialShell,
# home-manager, snapd, the unfree allow-list, the vscode-extensions overlay).
# A host supplies only what is specific to it, so a host definition can live
# outside this repo and consume it as `dots.lib.mkNixos` / `dots.lib.mkHome`.
#
# Module order is preserved exactly from the per-host blocks these replaced:
# list-valued options merge in module order, so reordering could change a
# system's derivation.
{inputs}: let
  inherit (inputs) nixpkgs home-manager;
  system = "x86_64-linux";

  unfreeAllowList = import ../modules/shared/unfree.nix;
  mkUnfreePredicate = extra: pkg: builtins.elem (nixpkgs.lib.getName pkg) (unfreeAllowList ++ extra);

  overlays = [inputs.nix-vscode-extensions.overlays.default];
in {
  # A NixOS system with home-manager for one user.
  #   modules       host NixOS modules, placed before the shared stack
  #   modulesAfter  NixOS modules placed after it
  #   home          the user's home-manager module (a path)
  #   unfreeExtra   unfree package names allowed on top of the shared list
  #   extraInputs   extra flake inputs, merged into the `inputs` modules receive
  mkNixos = {
    modules,
    home,
    user ? "cathe",
    modulesAfter ? [],
    unfreeExtra ? [],
    extraInputs ? {},
  }: let
    inputs' = inputs // extraInputs;
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inputs = inputs';};
      modules =
        [
          {
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
          inputs.stylix.nixosModules.stylix
          inputs.dms.nixosModules.dank-material-shell
          inputs.dms-plugin-registry.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inputs = inputs';};
              sharedModules = [
                inputs.dms.homeModules.dank-material-shell
                inputs.dms-plugin-registry.homeModules.default
                inputs.danksearch.homeModules.default
                inputs.dcal.homeModules.default
              ];
              users.${user} = import home;
            };
          }

          inputs.nix-snapd.nixosModules.default
          {
            services.snap.enable = true;
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
      extraSpecialArgs = {inputs = inputs // extraInputs;};
      modules =
        modules
        ++ [
          inputs.stylix.homeModules.stylix
          inputs.dms.homeModules.dank-material-shell
          inputs.dms-plugin-registry.homeModules.default
          inputs.danksearch.homeModules.default
          inputs.dcal.homeModules.default
        ];
    };
}
