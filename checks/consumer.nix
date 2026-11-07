# Evaluation-only checks standing in for downstream flakes that use dots by file
# path instead of through the host constructors. dots cannot see such consumers,
# so these reproduce how one actually does it (modelled on a real downstream
# flake): the shell and nvim modules imported by path, and a vscode module of its
# own that builds profiles from dots' individual feature files, `groups.nix`,
# `lib.nix`, `keybindings.nix` and `settings/global`, never importing dots'
# `modules/home/vscode/default.nix`.
#
# Only the derivation path is computed (written to a file, nothing is built), so
# `nix flake check` stays cheap.
{inputs}: let
  system = "x86_64-linux";
  dots = inputs.self;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [inputs.nix-vscode-extensions.overlays.default];
    config.allowUnfree = true;
  };

  base = {
    home.username = "consumer";
    home.homeDirectory = "/home/consumer";
    home.stateVersion = "25.11";
  };

  # A downstream vscode module: deep imports of dots' files, own list of profiles.
  vscodeModule = {
    pkgs,
    config,
    lib,
    ...
  }: let
    dotsVscode = "${dots}/modules/home/vscode";
    globalSettings = import "${dotsVscode}/settings/global";
    globalKeybindings = import "${dotsVscode}/keybindings.nix";
    vscodeLib = import "${dotsVscode}/lib.nix" {inherit lib globalSettings globalKeybindings;};
    features =
      builtins.mapAttrs (_: path: import path {inherit pkgs config;})
      (lib.genAttrs [
          "nix"
          "git"
          "markdown"
          "better-comments"
          "tab-groups"
          "toml"
          "json"
          "kdl"
          "theme"
          "utils"
          "claude"
          "latex"
          "java"
          "python"
          "vsrocq"
          "haskell"
          "ocaml"
          "disable-breakpoint"
          "unicode-math-symbols"
        ]
        (name: "${dotsVscode}/features/${name}.nix"));
    groups = import "${dotsVscode}/groups.nix" {inherit features;};
  in {
    imports = ["${dotsVscode}/profile-ui-state.nix"];
    programs.vscode = {
      enable = true;
      mutableExtensionsDir = false;
      profiles = {
        default = (vscodeLib.mkProfile groups.default).profile;
        java = (vscodeLib.mkProfile groups.java).profile;
        python = (vscodeLib.mkProfile groups.python).profile;
        rocq = (vscodeLib.mkProfile groups.rocq).profile;
        haskell = (vscodeLib.mkProfile groups.haskell).profile;
      };
    };
  };

  consumerConfig = modules:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inputs = inputs // {inherit dots;};};
      modules = [base] ++ modules;
    };

  consumer = modules: (consumerConfig modules).activationPackage.drvPath;

  check = name: modules:
    pkgs.writeText name (builtins.unsafeDiscardStringContext (consumer modules));
  # The newer shape: dots' area modules (homeModules.shell/nvim/vscode), VS Code
  # with a few profiles, on a nixpkgs without the nix-vscode-extensions overlay
  # (the vscode module brings its own). Asserts that a profile set without
  # Erlang doesn't get Erlang on VS Code's PATH.
  modulesConsumer = let
    hm = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        base
        dots.homeModules.shell
        dots.homeModules.nvim
        dots.homeModules.vscode
        {
          dots.vscode = {
            enable = true;
            profiles = ["java" "python" "rocq" "haskell"];
          };
        }
      ];
    };
    vscode = hm.config.programs.vscode;
  in
    assert inputs.nixpkgs.lib.assertMsg (inputs.nixpkgs.lib.attrNames vscode.profiles == ["default" "haskell" "java" "python" "rocq"])
    "consumer-modules: unexpected profiles ${toString (inputs.nixpkgs.lib.attrNames vscode.profiles)}";
    assert inputs.nixpkgs.lib.assertMsg (hm.config.dots.vscode.extraPath == [])
    "consumer-modules: Erlang reached VS Code's PATH without an Erlang profile";
      hm.activationPackage.drvPath;

  # The globalprotect module imported by path on its own, as a second user would
  # (it is self-contained, so nothing else of dots' needs to come with it). Enabled
  # with a portal it evaluates; enabled without one it must be refused. It must
  # also register the handler for the sign-in's `globalprotectcallback:` link, or
  # the browser's final page does nothing.
  globalprotectModule = "${dots}/modules/home/globalprotect";
  globalprotectConsumer = let
    noPortalEvaluates = (builtins.tryEval (consumer [globalprotectModule {dots.globalprotect.enable = true;}])).success;
    modules = [
      globalprotectModule
      {
        dots.globalprotect = {
          enable = true;
          portal = "vpn.example.com";
        };
      }
    ];
    gpConfig = (consumerConfig modules).config;
    callback = gpConfig.xdg.desktopEntries.globalprotect-callback;
    # The menu's `up` runs in its own tmux session (so its window can be closed
    # while connected); `down` is a plain terminal.
    menu = gpConfig.dots.services.globalprotect;
  in
    assert inputs.nixpkgs.lib.assertMsg (!noPortalEvaluates)
    "consumer-globalprotect: enabling dots.globalprotect without a portal evaluated";
    assert inputs.nixpkgs.lib.assertMsg (callback.mimeType == ["x-scheme-handler/globalprotectcallback"])
    "consumer-globalprotect: the callback desktop entry does not handle globalprotectcallback:";
    assert inputs.nixpkgs.lib.assertMsg (inputs.nixpkgs.lib.hasSuffix "/bin/gpclient launch-gui %u" callback.exec)
    "consumer-globalprotect: the callback desktop entry does not run `gpclient launch-gui %u`";
    assert inputs.nixpkgs.lib.assertMsg (inputs.nixpkgs.lib.elem "new-session" menu.up && inputs.nixpkgs.lib.elem "-A" menu.up)
    "consumer-globalprotect: the menu's `up` does not attach-or-create a tmux session";
    assert inputs.nixpkgs.lib.assertMsg (!(inputs.nixpkgs.lib.elem "new-session" menu.down))
    "consumer-globalprotect: the menu's `down` runs in tmux; it must be a plain terminal";
    assert inputs.nixpkgs.lib.assertMsg (builtins.length menu.actions == 1 && (builtins.head menu.actions).terminal && inputs.nixpkgs.lib.last (builtins.head menu.actions).argv == "attach")
    "consumer-globalprotect: the menu's one action is not a terminal `globalprotect attach`";
      check "consumer-globalprotect-evaluates" modules;

  # The dictation module imported by path on its own (it needs only home-manager's
  # own niri module). Enabled, it must configure voxtype for Parakeet with its own
  # hotkey off (voxtype's default is on, and would grab every keyboard), let a
  # host replace any default, run the daemon as a user unit and add the niri bind
  # file; disabled, it must add nothing.
  dictationModule = "${dots}/modules/home/dictation";
  dictationConsumer = let
    lib = inputs.nixpkgs.lib;
    on = (consumerConfig [dictationModule {dots.dictation.enable = true;}]).config;
    custom =
      (consumerConfig [
        dictationModule
        {
          dots.dictation = {
            enable = true;
            model = "v2";
            keyboardLayout = "us";
            settings.output.mode = "clipboard";
          };
        }
      ]).config;
    off = (consumerConfig [dictationModule]).config;
    settings = on.dots.dictation.settings;
  in
    assert lib.assertMsg (settings.engine == "parakeet" && settings.parakeet.model_type == "tdt")
    "consumer-dictation: voxtype is not configured for the Parakeet TDT engine";
    assert lib.assertMsg (settings.hotkey.enabled == false)
    "consumer-dictation: voxtype's own hotkey is not turned off";
    assert lib.assertMsg (settings.output.driver_order == ["dotool" "clipboard"])
    "consumer-dictation: text is not typed by dotool with only the clipboard as a fallback (wtype corrupts text in Electron apps)";
    assert lib.assertMsg (settings.output.dotool_xkb_layout == "gb" && custom.dots.dictation.settings.output.dotool_xkb_layout == "us")
    "consumer-dictation: dotool's layout does not follow dots.dictation.keyboardLayout";
    assert lib.assertMsg (settings.osd.enabled == false)
    "consumer-dictation: voxtype's overlay is not turned off (this build cannot start it)";
    assert lib.assertMsg (lib.hasSuffix "-parakeet-tdt-0.6b-v2-int8" settings.parakeet.model)
    "consumer-dictation: the default model is not the int8 v2 directory (${settings.parakeet.model})";
    assert lib.assertMsg (lib.hasSuffix "-parakeet-tdt-0.6b-v2" custom.dots.dictation.settings.parakeet.model)
    "consumer-dictation: dots.dictation.model = \"v2\" did not select the fp32 directory";
    assert lib.assertMsg (custom.dots.dictation.settings.output.mode == "clipboard" && custom.dots.dictation.settings.hotkey.enabled == false)
    "consumer-dictation: a host's setting was lost, or setting one key dropped the defaults";
    assert lib.assertMsg (lib.hasSuffix "/bin/voxtype daemon" (lib.head on.systemd.user.services.voxtype.Service.ExecStart))
    "consumer-dictation: the unit does not run `voxtype daemon`";
    assert lib.assertMsg (on.xdg.configFile ? "voxtype/config.toml")
    "consumer-dictation: no config file is installed";
    assert lib.assertMsg (lib.hasInfix "dictation-binds.kdl" on.wayland.windowManager.niri.extraConfig)
    "consumer-dictation: niri does not include the bind file";
    assert lib.assertMsg (!(off.systemd.user.services ? voxtype) && !(off.xdg.configFile ? "voxtype/config.toml") && !(lib.hasInfix "dictation" off.wayland.windowManager.niri.extraConfig))
    "consumer-dictation: the disabled module still adds a unit, a config file or a niri include";
      check "consumer-dictation-evaluates" [dictationModule {dots.dictation.enable = true;}];
in {
  # The globalprotect module alone, by path.
  consumer-globalprotect = globalprotectConsumer;
  # The dictation module alone, by path.
  consumer-dictation = dictationConsumer;
  # The area modules with dots.vscode, as a second user's flake uses them.
  consumer-modules = pkgs.writeText "consumer-modules-evaluates" (builtins.unsafeDiscardStringContext modulesConsumer);
  # shell + nvim by path, plus the vscode module above: the full downstream shape.
  consumer-full = check "consumer-full-evaluates" [
    "${dots}/modules/home/shell"
    "${dots}/modules/home/nvim"
    vscodeModule
  ];
  # The same without nvim: the shell module plus the vscode module. Nothing here may
  # rely on the nvim module happening to declare an option that others read.
  consumer-no-nvim = check "consumer-no-nvim-evaluates" [
    "${dots}/modules/home/shell"
    vscodeModule
  ];
}
