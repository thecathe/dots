# Evaluation-only checks standing in for downstream flakes that use dots' home
# modules without the host constructors. dots cannot see such consumers, so these
# reproduce how one does it: the area modules (`homeModules.*`) as a real
# downstream flake uses them, and single modules imported by path. (Until
# 2026-11-22 two more checks rebuilt that flake's older shape, a vscode module of
# its own built from dots' feature files by path; it moved to `homeModules` on
# 2026-10-29, so they were dropped.)
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

  # The flameshot module imported by path on its own. Enabled, it must run the
  # daemon as a user unit (a short-lived `flameshot gui` would take the pins and
  # the clipboard with it when it exits), write the config with the tray icon off,
  # and add one niri file: Flameshot on Print, niri's own selector on Shift+Print,
  # and a rule that floats pins (title fixed in Flameshot's source). A host can
  # move the keys and replace any default; disabled (it is on by default), the module adds nothing.
  flameshotModule = "${dots}/modules/home/flameshot";
  flameshotConsumer = let
    lib = inputs.nixpkgs.lib;
    on = (consumerConfig [flameshotModule {dots.flameshot.enable = true;}]).config;
    custom =
      (consumerConfig [
        flameshotModule
        {
          dots.flameshot = {
            enable = true;
            bind = "Mod+Shift+S";
            niriBind = null;
            settings.General.disabledTrayIcon = false;
          };
        }
      ]).config;
    off = (consumerConfig [flameshotModule {dots.flameshot.enable = false;}]).config;
    # The default is on: importing the module is enough (a host that does not want it says so).
    byDefault = (consumerConfig [flameshotModule]).config;
    # Two outputs: the wlr Screenshot portal and the per-output wrapper on Print.
    multiModules = [
      flameshotModule
      {
        dots.flameshot = {
          enable = true;
          wlrScreenshotPortal = true;
          pointerOutput = true;
        };
      }
    ];
    multi = (consumerConfig multiModules).config;
    # A host whose portal is niri's own (the work laptop): the patched Flameshot and
    # the wrapper that hands Print to niri's selector while more than one output is on.
    laptopModules = [
      flameshotModule
      {
        dots.flameshot = {
          enable = true;
          boundingBoxCrop = true;
          singleOutputOnly = true;
        };
      }
    ];
    laptop = (consumerConfig laptopModules).config;
    # The same without the patch: reading the kdl builds the wrapper, which carries its
    # Flameshot, and the patched one would be compiled by a check that only evaluates.
    laptopStock =
      (consumerConfig [
        flameshotModule
        {
          dots.flameshot = {
            enable = true;
            singleOutputOnly = true;
          };
        }
      ]).config;
    # The two answers to more than one output cannot be combined with the fallback.
    conflict =
      (consumerConfig [
        flameshotModule
        {
          dots.flameshot = {
            enable = true;
            singleOutputOnly = true;
            pointerOutput = true;
          };
        }
      ]).config;
    # A host that still sets the old list (nixos did until the order was read from the
    # compositor) keeps the wrapper on Print, and is told to move to pointerOutput.
    legacy =
      (consumerConfig [
        flameshotModule
        {
          dots.flameshot = {
            enable = true;
            screenOrder = ["HDMI-A-1" "DP-1"];
          };
        }
      ]).config;
    # The patch together with the wlr portal: its grim wrapper stops padding.
    bothModules = [
      flameshotModule
      {
        dots.flameshot = {
          enable = true;
          wlrScreenshotPortal = true;
          boundingBoxCrop = true;
        };
      }
    ];
    execStart = c: lib.head (lib.toList c.systemd.user.services.flameshot.Service.ExecStart);
    # The file the one `include "<path>"` line in niri's config points at, read.
    # replaceStrings keeps the string context that says the path is a build
    # output (builtins.match would drop it, and pure evaluation then refuses the
    # read); the file is a writeText, so reading it builds a few bytes.
    niriFile = c: let
      extra = c.wayland.windowManager.niri.extraConfig;
      path = builtins.replaceStrings ["include" "\"" "\n" " "] ["" "" "" ""] extra;
    in
      assert lib.assertMsg (lib.hasInfix "include \"" extra && lib.hasSuffix "flameshot.kdl" path)
      "consumer-flameshot: niri's extraConfig is not the one include of flameshot.kdl";
        builtins.readFile path;
    iniFile = c: builtins.readFile c.xdg.configFile."flameshot/flameshot.ini".source;
  in
    assert lib.assertMsg (lib.hasSuffix "/bin/flameshot" (lib.head (lib.toList on.systemd.user.services.flameshot.Service.ExecStart)))
    "consumer-flameshot: the unit does not run the flameshot daemon";
    assert lib.assertMsg (byDefault.systemd.user.services ? flameshot && byDefault.dots.flameshot.enable)
    "consumer-flameshot: importing the module alone does not turn Flameshot on (the default is on)";
    assert lib.assertMsg (lib.hasInfix "disabledTrayIcon=true" (iniFile on) && lib.hasInfix "showStartupLaunchMessage=false" (iniFile on) && lib.hasInfix "showAbortNotification=false" (iniFile on))
    "consumer-flameshot: the daemon would show a tray icon, or a startup or abort notification";
    assert lib.assertMsg (lib.hasInfix "Screenshots" (iniFile on) && lib.hasInfix "saveAfterCopy=true" (iniFile on))
    "consumer-flameshot: screenshots do not land in ~/Pictures/Screenshots, or copying does not save, as niri's did";
    assert lib.assertMsg (lib.hasInfix "disabledTrayIcon=false" (iniFile custom))
    "consumer-flameshot: a host's setting did not replace the default";
    assert lib.assertMsg (lib.hasInfix "Print repeat=false" (niriFile on) && lib.hasInfix "/bin/flameshot\" \"gui\"" (niriFile on))
    "consumer-flameshot: Print does not run `flameshot gui`";
    assert lib.assertMsg (lib.hasInfix "Shift+Print hotkey-overlay-title=\"Screenshot: niri's own selector\" { screenshot; }" (niriFile on))
    "consumer-flameshot: niri's own selector is not kept on Shift+Print";
    assert lib.assertMsg (lib.hasInfix "match title=\"^flameshot-pin$\"" (niriFile on) && lib.hasInfix "open-floating true" (niriFile on))
    "consumer-flameshot: pinned screenshots are not set to float";
    assert lib.assertMsg (lib.hasInfix "Mod+Shift+S repeat=false" (niriFile custom) && !(lib.hasInfix "{ screenshot; }" (niriFile custom)))
    "consumer-flameshot: bind/niriBind did not move or drop the keys";
    assert lib.assertMsg (!(off.systemd.user.services ? flameshot) && !(off.xdg.configFile ? "flameshot/flameshot.ini") && !(lib.hasInfix "flameshot" off.wayland.windowManager.niri.extraConfig))
    "consumer-flameshot: the disabled module still adds a unit, a config file or a niri include";
    assert lib.assertMsg (!(on.systemd.user.services ? xdg-desktop-portal-wlr) && !(on.xdg.portal.config ? niri))
    "consumer-flameshot: the wlr portal is added although wlrScreenshotPortal is off";
    assert lib.assertMsg (lib.hasInfix "/bin/flameshot\" \"gui\"" (niriFile on) && !(lib.hasInfix "flameshot-screen" (niriFile on)))
    "consumer-flameshot: without pointerOutput, Print is not plain `flameshot gui`";
    assert lib.assertMsg (multi.xdg.portal.config.niri."org.freedesktop.impl.portal.Screenshot" == "wlr")
    "consumer-flameshot: Screenshot is not routed to the wlr portal";
    assert lib.assertMsg (multi.xdg.portal.config.niri.default == "gnome;gtk" && multi.xdg.portal.config.niri."org.freedesktop.impl.portal.Access" == "gtk" && multi.xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" == "gtk")
    "consumer-flameshot: the user-level portal config dropped part of niri's list (it replaces the system file rather than merging)";
    assert lib.assertMsg (lib.any (p: lib.hasInfix "xdg-desktop-portal-wlr" (toString p)) multi.xdg.portal.extraPortals)
    "consumer-flameshot: xdg-desktop-portal-wlr is not among the portals";
    assert lib.assertMsg (multi.systemd.user.services.xdg-desktop-portal-wlr.Service.BusName == "org.freedesktop.impl.portal.desktop.wlr")
    "consumer-flameshot: the wlr portal unit does not own the wlr portal name";
    assert lib.assertMsg (!(lib.hasPrefix (toString pkgs.xdg-desktop-portal-wlr) (lib.head (lib.toList multi.systemd.user.services.xdg-desktop-portal-wlr.Service.ExecStart))) && multi.dots.flameshot.portalPngLevel == 0)
    "consumer-flameshot: the wlr portal is the stock package, not the one built with the uncompressed-PNG grim";
    assert lib.assertMsg (lib.hasInfix "/bin/flameshot-screen\"" (niriFile multi) && !(lib.hasInfix "\"gui\"" (niriFile multi)))
    "consumer-flameshot: with pointerOutput, Print does not run the per-output wrapper";
    assert lib.assertMsg (lib.hasInfix "/bin/flameshot-screen\"" (niriFile legacy) && lib.any (w: lib.hasInfix "screenOrder is deprecated" w) legacy.warnings)
    "consumer-flameshot: a host that still sets screenOrder lost the per-output wrapper, or is not told the option is deprecated";
    assert lib.assertMsg (!(lib.any (w: lib.hasInfix "screenOrder" w) multi.warnings))
    "consumer-flameshot: pointerOutput on its own draws the screenOrder deprecation warning";
    assert lib.assertMsg (lib.hasPrefix (toString pkgs.flameshot) (execStart on) && lib.hasPrefix (toString pkgs.flameshot) (execStart multi))
    "consumer-flameshot: Flameshot is not the stock package where boundingBoxCrop is off (nixos would rebuild it)";
    assert lib.assertMsg (!(lib.hasPrefix (toString pkgs.flameshot) (execStart laptop)) && lib.hasSuffix "/bin/flameshot" (execStart laptop))
    "consumer-flameshot: boundingBoxCrop does not run a patched Flameshot";
    assert lib.assertMsg (lib.any (p: (p.pname or "") == "flameshot" && lib.any (x: lib.hasSuffix "bounding-box-crop.patch" (toString x)) (p.patches or [])) laptop.home.packages)
    "consumer-flameshot: the patched Flameshot is not the one installed, or it lacks the crop patch";
    assert lib.assertMsg (lib.hasInfix "/bin/flameshot-or-niri\"" (niriFile laptopStock) && !(lib.hasInfix "\"gui\"" (niriFile laptopStock)))
    "consumer-flameshot: singleOutputOnly does not put the fallback wrapper on Print";
    assert lib.assertMsg (!(laptop.systemd.user.services ? xdg-desktop-portal-wlr) && !(laptop.xdg.portal.config ? niri))
    "consumer-flameshot: the laptop options add the wlr portal, which Ubuntu's portal frontend would not see";
    assert lib.assertMsg (!(builtins.tryEval conflict.home.username).success)
    "consumer-flameshot: singleOutputOnly together with pointerOutput or wlrScreenshotPortal is not refused";
      pkgs.writeText "consumer-flameshot-evaluates" (builtins.unsafeDiscardStringContext (
        consumer [flameshotModule {dots.flameshot.enable = true;}] + consumer multiModules + consumer laptopModules + consumer bothModules
      ));

  # The DMS bar indicator for dictation (modules/home/dank/dictation-status.nix) next
  # to the dictation module, with the DMS plugin options stood in for by a bare
  # attribute set (the real ones come from DMS's own home-manager module, which this
  # does not load). Enabled, the plugin must be installed and told to follow voxtype's
  # status with the very binary the daemon runs; disabled, it must not exist at all, so
  # a host without dictation gets no plugin. The shared settings.json must also place
  # the widget in a bar, or the plugin would be installed and never drawn.
  dictationWidgetConsumer = let
    lib = inputs.nixpkgs.lib;
    # Also the DMS area's own switch, which modules/home/dank/default.nix declares and
    # this file, imported alone, does not.
    dmsStub = {lib, ...}: {
      options.programs.dank-material-shell.plugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
      options.dots.dank.enable = lib.mkEnableOption "DMS" // {default = true;};
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
  # install dlsync and orient and put orient's SessionStart hook into the Claude
  # Code settings (run with --hook so its exit status stays 0 and its output
  # stays Claude's context; pull-only because pushing is the user's call), plus
  # the one permission rule for `orient push-workbench`; with the hook switched
  # off, or no clone, it must add neither, and the disabled module installs
  # nothing.
  devlogModule = "${dots}/modules/home/devlog";
  devlogConsumer = let
    lib = inputs.nixpkgs.lib;
    clone = {dots.devlog.dir = "/home/consumer/devlog";};
    on = (consumerConfig [devlogModule clone]).config;
    noHook = (consumerConfig [devlogModule clone {dots.devlog.claudeHook = false;}]).config;
    off = (consumerConfig [devlogModule]).config;
    script = c: c.home.activation.orientClaudeHook.data;
    has = name: c: lib.any (p: lib.getName p == name) c.home.packages;
  in
    assert lib.assertMsg (has "dlsync" on && has "dlsync" noHook && !(has "dlsync" off))
    "consumer-devlog: dlsync is installed when, and only when, a clone is configured";
    assert lib.assertMsg (has "orient" on && has "orient" noHook && !(has "orient" off))
    "consumer-devlog: orient is installed when, and only when, a clone is configured";
    assert lib.assertMsg (lib.hasInfix "dots:managed" (script on) && lib.hasInfix "startup|resume" (script on) && lib.hasInfix "bin/orient --hook" (script on))
    "consumer-devlog: the SessionStart hook is not orient --hook on startup and resume";
    assert lib.assertMsg (!(lib.hasInfix "--push" (script on)))
    "consumer-devlog: the session hook pushes; pushing is the user's call";
    assert lib.assertMsg (lib.hasInfix ''["Bash(orient push-workbench)"]'' (script on) && !(lib.hasInfix "--create" (script on)))
    "consumer-devlog: the permission is not exactly the one guarded push, without --create";
    assert lib.assertMsg (!(lib.hasInfix "startup|resume" (script noHook)) && !(lib.hasInfix "startup|resume" (script off)))
    "consumer-devlog: the hook is added although it is switched off, or there is no clone";
    assert lib.assertMsg (lib.hasInfix "--argjson allow '[]'" (script noHook) && lib.hasInfix "--argjson allow '[]'" (script off))
    "consumer-devlog: the permission is allowed although the hook is switched off, or there is no clone";
      check "consumer-devlog-evaluates" [devlogModule clone];

  # The repos module through its export, `homeModules.repos`, as a second user's
  # flake imports it: the CLI alone, with nothing of DankMaterialShell (the bar
  # menu over it is in `default` only). Enabled it installs `repos`, built from
  # the options: the same derivation package.nix gives for the same arguments,
  # so each option reaches the script, and a different one does not. Disabled
  # (it is opt-in) it adds nothing. The export declares no option but its own,
  # so the menu's wiring did not come with it.
  reposConsumer = let
    lib = inputs.nixpkgs.lib;
    package = import "${dots}/modules/home/repos/package.nix";
    root = "/home/consumer/Documents/git";
    args = {
      owners = ["me"];
      exclude = ["me/big"];
      integration = {"me/x" = "dev";};
    };
    on =
      (consumerConfig [
        dots.homeModules.repos
        {
          dots.repos = {
            enable = true;
            owners = args.owners;
            exclude = args.exclude;
            integrationBranch = args.integration;
          };
        }
      ]).config;
    off = (consumerConfig [dots.homeModules.repos]).config;
    has = name: c: lib.any (p: lib.getName p == name) c.home.packages;
  in
    assert lib.assertMsg (has "repos" on && !(has "repos" off))
    "consumer-repos: `repos` is installed when, and only when, dots.repos.enable is set";
    assert lib.assertMsg (on.dots.repos.root == root)
    "consumer-repos: the root does not default to ~/Documents/git (${on.dots.repos.root})";
    assert lib.assertMsg (on.dots.repos.package.drvPath == (package ({inherit pkgs root;} // args)).drvPath)
    "consumer-repos: the package is not package.nix built from the options";
    assert lib.assertMsg (on.dots.repos.package.drvPath != (package ({inherit pkgs root;} // args // {owners = ["you"];})).drvPath)
    "consumer-repos: a different owner built the same package, so the options do not reach the script";
    assert lib.assertMsg (lib.attrNames on.dots == ["repos"])
    "consumer-repos: the export declares options besides dots.repos (${toString (lib.attrNames on.dots)})";
      check "consumer-repos-evaluates" [dots.homeModules.repos {dots.repos.enable = true;}];
in {
  # The devlog module alone, by path.
  consumer-devlog = devlogConsumer;
  # The globalprotect module alone, by path.
  consumer-globalprotect = globalprotectConsumer;
  # The dictation module alone, by path.
  consumer-dictation = dictationConsumer;
  # The dictation bar indicator next to it, with DMS's plugin options stubbed.
  consumer-dictation-widget = dictationWidgetConsumer;
  # The flameshot module alone, by path.
  consumer-flameshot = flameshotConsumer;
  # The repos module through its export, as a second user's flake imports it.
  consumer-repos = reposConsumer;
  # The area modules with dots.vscode, as a second user's flake uses them.
  consumer-modules = pkgs.writeText "consumer-modules-evaluates" (builtins.unsafeDiscardStringContext modulesConsumer);
  # The area modules without nvim. Nothing here may rely on the nvim module
  # happening to declare an option that others read.
  consumer-no-nvim = check "consumer-no-nvim-evaluates" [
    dots.homeModules.shell
    dots.homeModules.vscode
    {dots.vscode.enable = true;}
  ];
}
