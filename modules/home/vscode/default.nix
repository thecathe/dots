# VS Code: dots' settings, keybindings and per-language profiles, behind
# dots.vscode. Another flake can import just this (dots.homeModules.vscode),
# turn it on and pick its profiles; only the profiles it lists are built, so
# nothing of the others (their extensions, their tools) reaches its system.
{
  lib,
  pkgs,
  config,
  dotsInputs,
  ...
}: let
  cfg = config.dots.vscode;

  # The features use nix-vscode-extensions' marketplace sets. A flake that
  # imports this module without that overlay gets it here, from dots' input.
  featurePkgs =
    if pkgs ? nix-vscode-extensions
    then pkgs
    else pkgs.extend dotsInputs.nix-vscode-extensions.overlays.default;

  globalSettings = import ./settings/global;
  globalKeybindings = import ./keybindings.nix;
  vscodeLib = import ./lib.nix {inherit lib globalSettings globalKeybindings;};
  localFeatures = builtins.mapAttrs (_: path:
    import path {
      inherit config;
      pkgs = featurePkgs;
    }) {
    nix = ./features/nix.nix;
    kdl = ./features/kdl.nix;
    ocaml = ./features/ocaml.nix;
    erlang = ./features/erlang.nix;
    go = ./features/go.nix;
    haskell = ./features/haskell.nix;
    python = ./features/python.nix;
    java = ./features/java.nix;
    sql = ./features/sql.nix;
    web = ./features/web.nix;
    ssh = ./features/ssh.nix;
    git = ./features/git.nix;
    pdf = ./features/pdf.nix;
    json = ./features/json.nix;
    toml = ./features/toml.nix;
    latex = ./features/latex.nix;
    vsrocq = ./features/vsrocq.nix;
    markdown = ./features/markdown.nix;
    languagetool = ./features/languagetool.nix;
    tab-groups = ./features/tab-groups.nix;
    spellcheck = ./features/spellcheck.nix;
    better-comments = ./features/better-comments.nix;
    disable-breakpoint = ./features/disable-breakpoint.nix;
    unicode-math-symbols = ./features/unicode-math-symbols.nix;
    claude = ./features/claude.nix;
    theme = ./features/theme.nix;
    utils = ./features/utils.nix;
  };
  # forest-keeper pin/patches, forester-edit, settings and keybindings live in
  # the vscode-forester flake (the single source for the Forester setup).
  # Only evaluated when a listed profile uses it.
  features =
    localFeatures
    // {
      forester = dotsInputs.vscode-forester.lib.vscodeFeature featurePkgs;
    };
  # profile name -> its list of features (groups.nix).
  groups = import ./groups.nix {inherit features;};
  otherProfiles = lib.remove "default" (lib.attrNames groups);

  profiles = ["default"] ++ cfg.profiles;
  enabledFeatures = lib.concatMap (name: groups.${name}) profiles;

  # Programs an extension shells out to and expects on PATH (a feature's
  # `extraPath`), from the enabled profiles' features only.
  extraPath = lib.unique (lib.concatMap (f: f.extraPath or []) enabledFeatures);
in {
  # ../nixd.nix declares dots.nixd, which features/nix.nix reads: imported here so the
  # vscode module also works when imported on its own (modules dedupe by path).
  imports = [./profile-ui-state.nix ./workspaces.nix ../nixd.nix];

  options.dots.vscode = {
    enable = lib.mkEnableOption "VS Code with dots' settings, keybindings and profiles";
    profiles = lib.mkOption {
      type = lib.types.listOf (lib.types.enum otherProfiles);
      default = otherProfiles;
      defaultText = lib.literalMD "every profile in `groups.nix`";
      example = ["python" "rocq"];
      description = "The profiles to build besides `default`, which is always built. Names are those in groups.nix.";
    };
    extraPath = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
      internal = true;
      default = extraPath;
      description = "What the enabled profiles' features put on VS Code's PATH (their extraPath).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      # Nix never ships setuid-root binaries in the store (only NixOS's
      # security.wrappers provides that; a standalone home-manager host has
      # none - same class of issue as the hosts repo's worklaptop/modules/wm/niri.nix's
      # swaylock/unix_chkpwd fix). Electron's chrome-sandbox helper needs to be
      # setuid-root to use the SUID sandbox, so the unwrapped nix-store vscode
      # refuses to launch a GUI window at all ("SUID sandbox helper binary...
      # is not configured correctly"). --no-sandbox skips that requirement.
      #
      # The PATH prefix is the enabled features' extraPath: today only erlang's
      # (rebar3/escript for pgourlain.erlang's bridge, see features/erlang.nix),
      # so only a machine with an Erlang-using profile gets Erlang. It is a
      # safety net while per-profile extension activation stays an upstream
      # weak point (nix-community/home-manager#7880, #8793).
      package = pkgs.symlinkJoin {
        name = "vscode-no-sandbox";
        paths = [pkgs.vscode];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild =
          ''
            wrapProgram $out/bin/code --add-flags "--no-sandbox"''
          + lib.optionalString (extraPath != []) " --prefix PATH : ${lib.makeBinPath extraPath}"
          + "\n";
      };
      # false because profiles beyond `default` are declared below; the module
      # itself only supports mutableExtensionsDir=true when no non-default
      # profiles exist (otherwise it's a no-op with a warning anyway).
      mutableExtensionsDir = false;
      # Must set icons manually in vscode.
      profiles = lib.genAttrs profiles (name:
        (vscodeLib.mkProfile groups.${name}).profile
        // lib.optionalAttrs (name == "default") {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;
        });
    };

    # UI layout persistence for the profiles above (globalStorage dirs + seeding
    # from the default profile). Standalone so other configs can import it too.
    programs.vscode.profileUiState.filesContainer = "workbench.views.service.sidebar.4337fe0b-3e0d-40ce-9701-c62f345cfd7a";
  };
}
