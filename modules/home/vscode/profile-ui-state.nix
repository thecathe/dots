# Standalone home-manager module: make UI layout persist for declared VSCode
# profiles. Safe to import on its own, e.g. from another flake:
#
#   imports = ["${inputs.dots}/modules/home/vscode/profile-ui-state.nix"];
#
# It reads the profile names from `programs.vscode.profiles`, so it works with
# whatever profiles the importing config declares, however they are built.
#
# Two things, both needed:
#  1. Create profiles/<name>/globalStorage/. Home-manager registers non-default
#     profiles in storage.json but never creates that dir (VSCode only does so
#     when a profile is created through its UI). Without it, state.vscdb fails
#     with SQLITE_CANTOPEN, VSCode falls back to in-memory state, and no UI
#     layout is ever persisted for the profile.
#  2. Seed each profile's UI state from the *default* profile once (see
#     seed-ui-state.nix). Curate the layout in the default profile by hand;
#     quit VSCode before running the switch so the seed can be applied.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.vscode.profileUiState;
  profileNames =
    builtins.filter (n: n != "default") (builtins.attrNames config.programs.vscode.profiles);
in {
  options.programs.vscode.profileUiState = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create globalStorage for declared profiles and seed their UI layout from the default profile.";
    };
    seed = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the activation step that seeds profile UI layout from the default profile. Disable to only create the globalStorage dirs.";
    };
    filesContainer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "workbench.views.service.sidebar.4337fe0b-3e0d-40ce-9701-c62f345cfd7a";
      description = ''
        ID of the (generated) view container that holds the file tree in the
        default profile. If set, and the default profile's saved layout
        contains it, Open Editors, Outline and Timeline are moved into it
        (they can end up stranded in the never-shown Remote Explorer
        container). Container IDs are per-install; leave null to skip.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.genAttrs (map (n: ".config/Code/User/profiles/${n}/globalStorage/.keep") profileNames) (_: {text = "";});

    home.activation.vscodeSeedUiState = lib.mkIf cfg.seed (lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${import ./seed-ui-state.nix {
        inherit lib pkgs profileNames;
        inherit (cfg) filesContainer;
      }}/bin/vscode-seed-ui-state
    '');
  };
}
