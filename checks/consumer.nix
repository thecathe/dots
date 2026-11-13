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
    # LaTeX Workshop and vscode-pdf clash, so each profile has exactly one:
    # `default` carries latex, the others get vscode-pdf (groups.nix).
    assert let
      lib = inputs.nixpkgs.lib;
      has = id: profile: lib.elem id (map (e: e.vscodeExtUniqueId or "") vscode.profiles.${profile}.extensions);
    in
      lib.assertMsg
      (has "James-Yu.latex-workshop" "default"
        && !has "tomoki1207.pdf" "default"
        && lib.all (p: has "tomoki1207.pdf" p && !has "James-Yu.latex-workshop" p) ["java" "python" "rocq" "haskell"])
      "consumer-modules: a profile has both or neither of LaTeX Workshop and vscode-pdf";
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

  # The DMS bar indicator for dictation (modules/home/dank/dictation-status.nix) next
  # to the dictation module, with the DMS plugin options stood in for by a bare
  # attribute set (the real ones come from DMS's own home-manager module, which this
  # does not load). Enabled, the plugin must be installed and told to follow voxtype's
  # status with the very binary the daemon runs; disabled, it must not exist at all, so
  # a host without dictation gets no plugin. The shared settings.json must also place
  # the widget in a bar, or the plugin would be installed and never drawn.
  dictationWidgetConsumer = let
    lib = inputs.nixpkgs.lib;
    dmsStub = {lib, ...}: {
      options.programs.dank-material-shell.plugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
    };
    widgetModule = "${dots}/modules/home/dank/dictation-status.nix";
    modulesOn = [dictationModule widgetModule dmsStub {dots.dictation.enable = true;}];
    on = (consumerConfig modulesOn).config;
    off = (consumerConfig [dictationModule widgetModule dmsStub]).config;
    custom =
      (consumerConfig [
        dictationModule
        widgetModule
        dmsStub
        {
          dots.dictation = {
            enable = true;
            settings.audio.max_duration_secs = 180;
          };
        }
      ]).config;
    customPlugin = custom.programs.dank-material-shell.plugins.dictationStatus;
    plugin = on.programs.dank-material-shell.plugins.dictationStatus;
    manifest = builtins.fromJSON (builtins.readFile "${plugin.src}/plugin.json");
    settingsJson = builtins.fromJSON (builtins.readFile "${dots}/modules/home/dank/settings.json");
    widgetId = w:
      if builtins.isString w
      then w
      else w.id or "";
    inABar = lib.any (bar: lib.any (w: widgetId w == "dictationStatus") (bar.leftWidgets ++ bar.centerWidgets ++ bar.rightWidgets)) settingsJson.barConfigs;
  in
    assert lib.assertMsg (plugin.enable)
    "consumer-dictation-widget: the plugin is not enabled with dictation";
    assert lib.assertMsg (plugin.settings.statusCommand == ["${on.dots.dictation.package}/bin/voxtype" "status" "--follow" "--format" "json"])
    "consumer-dictation-widget: the plugin does not follow `voxtype status` of the package the daemon runs (${builtins.toJSON plugin.settings.statusCommand})";
    assert lib.assertMsg (manifest.id == "dictationStatus" && builtins.pathExists "${plugin.src}/${manifest.component}")
    "consumer-dictation-widget: the plugin's manifest does not name its id or an existing component";
    assert lib.assertMsg (!(off.programs.dank-material-shell.plugins ? dictationStatus))
    "consumer-dictation-widget: the plugin is installed although dictation is off";
    assert lib.assertMsg inABar
    "consumer-dictation-widget: no bar in settings.json lists the dictationStatus widget";
    assert lib.assertMsg (plugin.settings.maxDurationSecs == 60)
    "consumer-dictation-widget: with no host setting, the widget is not told voxtype's default limit of 60 s (${builtins.toJSON plugin.settings.maxDurationSecs})";
    assert lib.assertMsg (customPlugin.settings.maxDurationSecs == 180 && custom.dots.dictation.settings.audio.max_duration_secs == customPlugin.settings.maxDurationSecs)
    "consumer-dictation-widget: a host's audio.max_duration_secs does not reach the widget, or disagrees with the daemon's config";
      check "consumer-dictation-widget-evaluates" modulesOn;

  # The devlog module imported by path on its own. With a clone configured it must
  # install dlsync and put a quiet, pull-only SessionStart hook into the Claude
  # Code settings (quiet because a hook's stdout is Claude's context; pull-only
  # because pushing is the user's call); with the hook switched off, or no
  # clone, it must not add the hook, and the disabled module installs nothing.
  devlogModule = "${dots}/modules/home/devlog";
  devlogConsumer = let
    lib = inputs.nixpkgs.lib;
    clone = {dots.devlog.dir = "/home/consumer/devlog";};
    on = (consumerConfig [devlogModule clone]).config;
    noHook = (consumerConfig [devlogModule clone {dots.devlog.claudeHook = false;}]).config;
    off = (consumerConfig [devlogModule]).config;
    script = c: c.home.activation.dlsyncClaudeHook.data;
    hasDlsync = c: lib.any (p: lib.getName p == "dlsync") c.home.packages;
  in
    assert lib.assertMsg (hasDlsync on && hasDlsync noHook && !(hasDlsync off))
    "consumer-devlog: dlsync is installed when, and only when, a clone is configured";
    assert lib.assertMsg (lib.hasInfix "dots:managed" (script on) && lib.hasInfix "startup|resume" (script on) && lib.hasInfix "bin/dlsync --quiet" (script on))
    "consumer-devlog: the SessionStart hook is not a quiet dlsync on startup and resume";
    assert lib.assertMsg (!(lib.hasInfix "--push" (script on)))
    "consumer-devlog: the session hook pushes; pushing is the user's call";
    assert lib.assertMsg (!(lib.hasInfix "startup|resume" (script noHook)) && !(lib.hasInfix "startup|resume" (script off)))
    "consumer-devlog: the hook is added although it is switched off, or there is no clone";
      check "consumer-devlog-evaluates" [devlogModule clone];
in {
  # The devlog module alone, by path.
  consumer-devlog = devlogConsumer;
  # The globalprotect module alone, by path.
  consumer-globalprotect = globalprotectConsumer;
  # The dictation module alone, by path.
  consumer-dictation = dictationConsumer;
  # The dictation bar indicator next to it, with DMS's plugin options stubbed.
  consumer-dictation-widget = dictationWidgetConsumer;
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
