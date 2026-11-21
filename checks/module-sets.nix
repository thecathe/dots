# The exported module sets, `homeModules.default` and `nixosModules.default`,
# imported into a plain configuration: a bare `homeManagerConfiguration` and a
# bare `nixosSystem`, none of the constructors in lib/hosts.nix, and no upstream
# module added by hand. The README says "a host imports dots.homeModules.default";
# this is what proves that sentence. Before the sets imported the upstream
# modules whose options they set (DankMaterialShell, its plugin registry,
# DankSearch, DankCalendar, stylix) it was true only through `mkNixos` and
# `mkHome`, and nothing noticed, because every host used them.
#
# Only derivation paths are computed (written to a file, nothing is built), so
# `nix flake check` stays cheap.
{inputs}: let
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
  dots = inputs.self;

  # No overlays: nothing here may depend on what a constructor adds to pkgs.
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  base = {
    home.username = "consumer";
    home.homeDirectory = "/home/consumer";
    home.stateVersion = "25.11";
  };

  homeEval = modules:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [base] ++ modules;
    };
  home = modules: (homeEval modules).config;
  homeDrv = modules: (homeEval modules).activationPackage.drvPath;

  nixos = modules:
    lib.nixosSystem {
      inherit system;
      modules =
        [
          {
            dots.user.name = "consumer";
            nixpkgs.config.allowUnfree = true;
            system.stateVersion = "25.11";
            fileSystems."/" = {
              device = "/dev/disk/by-label/nixos";
              fsType = "ext4";
            };
            boot.loader.grub.enable = false;
          }
        ]
        ++ modules;
    };

  alone = home [dots.homeModules.default];
  withAreas = home [dots.homeModules.default dots.homeModules.shell dots.homeModules.vscode];
  nixosAlone = nixos [dots.nixosModules.default];
  nixosTwice = nixos [dots.nixosModules.default dots.nixosModules.default];

  # Named so that the failing assert says which one it was.
  written = name: text: assertion:
    lib.assertMsg assertion "module-sets-${name}: ${text}";

  # ---- the switches ------------------------------------------------------------
  # Every area of a set has a `dots.<area>.enable`. For each: what is true of a
  # configuration when the area is on and false when it is off. Cheap to read (no
  # derivation is evaluated), and each one is something a host would notice. Three
  # lists, so that a new switch has to be added to one of them:
  #  - the Areas: on by default, and turning one off removes what it adds;
  #  - the OffByDefault areas (personal, or reaching beyond the machine): off in a
  #    plain import, and turning one on adds what it adds;
  #  - the OptIn areas, off by default as well, which have checks of their own.
  # (devlog has no switch: a clone directory gates it.)
  hasPackage = name: pkgsList: lib.any (p: lib.getName p == name) pkgsList;
  homeAreas = {
    dank = c: c.programs.dank-material-shell.enable;
    firefox = c: c.programs.firefox.enable;
    git = c: c.programs.git.enable;
    navi = c: c.programs.navi.enable;
    nvim = c: c.programs.neovim.enable;
    shell = c: c.programs.zsh.enable;
    zathura = c: c.programs.zathura.enable;
    nixYourShell = c: c.programs.nix-your-shell.enable;
    niri = c: c.wayland.windowManager.niri.enable;
    flameshot = c: c.systemd.user.services ? flameshot;
    opam = c: c.home.activation ? opamGlobalSwitch;
    # stylix is not imported into a plain configuration, so what the switch changes
    # there is the warning that the theme is skipped.
    stylix = c: lib.any (w: lib.hasInfix "stylix" w) c.warnings;
    terminfo = c: c.home.file ? ".terminfo";
    latex = c: hasPackage "tectonic-wrapped" c.home.packages;
    music = c: hasPackage "playerctl" c.home.packages;
    wallpaper = c: hasPackage "bing-wallpaper-pin" c.home.packages;
    packages = c: hasPackage "wget" c.home.packages;
  };
  homeOffByDefault = {
    claude = c: c.programs.claude-code.enable;
    obsidian = c: c.programs.obsidian.enable;
  };
  homeOptIn = ["vscode" "dictation" "globalprotect" "repos"];

  nixosAreas = {
    direnv = c: c.programs.direnv.enable;
    firefox = c: c.programs.firefox.enable;
    # stylix adds fonts of its own, so look for one only dots' list has.
    fonts = c: lib.any (p: lib.hasInfix "mononoki" (toString p)) c.fonts.packages;
    git = c: c.programs.git.enable;
    nautilus = c: c.services.gvfs.enable;
    nixLd = c: c.programs.nix-ld.enable;
    niri = c: c.programs.niri.enable;
    stylix = c: c.stylix.enable;
    terminfo = c: lib.any (p: lib.hasInfix "-kitty-" (toString p) && lib.hasSuffix "-terminfo" (toString p)) c.environment.systemPackages;
    vscode = c: hasPackage "vscode" c.environment.systemPackages;
    zsh = c: c.programs.zsh.enable;
  };
  nixosOffByDefault = {
    claude = c: hasPackage "claude-code" c.environment.systemPackages;
    media = c: hasPackage "strawberry" c.environment.systemPackages;
    tailscale = c: c.services.tailscale.enable;
  };
  nixosOptIn = ["docker" "gpuScreenRecorder" "immich" "samba" "torrent" "waydroid"];

  # The names of the `dots.<x>.enable` options a configuration declares.
  switchNames = options: lib.attrNames (lib.filterAttrs (_: v: builtins.isAttrs v && (v.enable._type or "") == "option") options.dots);
  homeSwitches = switchNames (homeEval [dots.homeModules.default]).options;
  nixosSwitches = switchNames nixosAlone.options;

  off = areas: lib.genAttrs (lib.attrNames areas) (_: {enable = false;});
  failing = areas: configOf: lib.filter (a: !(areas.${a} (configOf a))) (lib.attrNames areas);
  failingOff = areas: configOf: lib.filter (a: areas.${a} (configOf a)) (lib.attrNames areas);
in {
  module-sets-home = assert written "home" "DankMaterialShell is not enabled by dots.homeModules.default" alone.programs.dank-material-shell.enable;
  assert written "home" "the DMS plugins dots installs are not there" (alone.programs.dank-material-shell.plugins ? dotsServices);
  # The set is keyed, so importing it again must change nothing at all.
  assert written "home" "importing the set twice changes the configuration" (homeDrv [dots.homeModules.default dots.homeModules.default] == homeDrv [dots.homeModules.default]);
  assert written "home" "importing the set together with the area modules fails or loses the VS Code option" (withAreas.dots.vscode.enable);
    pkgs.writeText "module-sets-home-evaluates" (builtins.unsafeDiscardStringContext (
      homeDrv [dots.homeModules.default]
      + homeDrv [dots.homeModules.default dots.homeModules.shell dots.homeModules.vscode]
    ));

  module-sets-nixos = assert written "nixos" "stylix is not enabled by dots.nixosModules.default" nixosAlone.config.stylix.enable;
  assert written "nixos" "importing the set twice changes the system" (nixosTwice.config.system.build.toplevel.drvPath == nixosAlone.config.system.build.toplevel.drvPath);
    pkgs.writeText "module-sets-nixos-evaluates" (builtins.unsafeDiscardStringContext (
      nixosAlone.config.system.build.toplevel.drvPath
    ));

  # dots.checkout is the one place that says where the working copy is: moving it
  # must move every module that reads or writes a file in it, and none may keep the
  # default location (or a bare $HOME/dots) written out by hand. Scripts are read
  # back from the store (a few bytes each), so what is checked is what would run.
  module-sets-checkout = let
    # Claude is off by default but writes into the checkout, so this turns it on to cover it.
    moved = home [
      dots.homeModules.default
      {
        dots.checkout = "/srv/dots";
        dots.claude.enable = true;
      }
    ];
    stale = text: lib.hasInfix "/home/consumer/dots" text || lib.hasInfix "$HOME/dots" text || lib.hasInfix "%h/dots" text || lib.hasInfix "~/dots" text;
    script = drv: builtins.readFile (toString drv);
    execStart = svc: lib.head (lib.toList svc.Service.ExecStart);
    pkgScript = name: let
      p = lib.findFirst (p: lib.getName p == name) (throw "module-sets-checkout: no package ${name}") moved.home.packages;
    in
      builtins.readFile "${p}/bin/${name}";
    texts = {
      "dank settings seed" = script (execStart moved.systemd.user.services.dank-settings-repair);
      "dank dock reset" = script (lib.head (lib.toList moved.systemd.user.services.dms.Service.ExecStartPre));
      "dank session seed" = moved.home.activation.dankMaterialShellSession.data;
      "claude settings link" = moved.home.activation.claudeCodeSettings.data;
      "zsh PATH and aliases" = moved.programs.zsh.initContent;
      "kitty nvim binding" = moved.programs.kitty.keybindings."ctrl+shift+d";
      "dank settings path unit" = lib.concatStrings moved.systemd.user.paths.dank-settings-repair.Path.PathModified;
      "bing-wallpaper-pin" = pkgScript "bing-wallpaper-pin";
      "bing-wallpaper-unpin" = pkgScript "bing-wallpaper-unpin";
    };
    leftovers = lib.filterAttrs (_: stale) texts;
    movedAll = lib.filterAttrs (_: t: !(lib.hasInfix "/srv/dots" t)) texts;
  in
    assert written "checkout" "the default is not the home directory's dots" (alone.dots.checkout == "/home/consumer/dots");
    assert written "checkout" "these still spell the default location by hand: ${toString (lib.attrNames leftovers)}" (leftovers == {});
    assert written "checkout" "these ignore dots.checkout: ${toString (lib.attrNames movedAll)}" (movedAll == {});
      pkgs.writeText "module-sets-checkout-evaluates" "ok";

  # Every area has a working switch: it is on by default, turning it off removes what
  # the area adds, no other area notices, and a configuration with every switch off
  # still evaluates. And a switch nobody tested (or a test for a switch that is gone)
  # fails here, so the lists above cannot drift from the options.
  module-sets-gates = let
    sortNames = names: lib.sort lib.lessThan names;
    homeOff = a: home [dots.homeModules.default {dots.${a}.enable = false;}];
    nixosOff = a: (nixos [dots.nixosModules.default {dots.${a}.enable = false;}]).config;
    homeOn = a: home [dots.homeModules.default {dots.${a}.enable = true;}];
    nixosOn = a: (nixos [dots.nixosModules.default {dots.${a}.enable = true;}]).config;
    on = areas: lib.genAttrs (lib.attrNames areas) (_: {enable = true;});
    names = xs: toString xs;
    homeCovered = sortNames (lib.attrNames homeAreas ++ lib.attrNames homeOffByDefault ++ homeOptIn);
    nixosCovered = sortNames (lib.attrNames nixosAreas ++ lib.attrNames nixosOffByDefault ++ nixosOptIn);
  in
    assert written "gates" "the home switches are ${names homeSwitches}, the tests and opt-ins cover ${names homeCovered}" (homeSwitches == homeCovered);
    assert written "gates" "the NixOS switches are ${names nixosSwitches}, the tests and opt-ins cover ${names nixosCovered}" (nixosSwitches == nixosCovered);
    assert written "gates" "these home areas are not on by default: ${names (failing homeAreas (_: alone))}" (failing homeAreas (_: alone) == []);
    assert written "gates" "these NixOS areas are not on by default: ${names (failing nixosAreas (_: nixosAlone.config))}" (failing nixosAreas (_: nixosAlone.config) == []);
    assert written "gates" "these home areas are on by default, but are meant to be off: ${names (failingOff homeOffByDefault (_: alone))}" (failingOff homeOffByDefault (_: alone) == []);
    assert written "gates" "these NixOS areas are on by default, but are meant to be off: ${names (failingOff nixosOffByDefault (_: nixosAlone.config))}" (failingOff nixosOffByDefault (_: nixosAlone.config) == []);
    assert written "gates" "turning these home areas off changes nothing: ${names (failingOff homeAreas homeOff)}" (failingOff homeAreas homeOff == []);
    assert written "gates" "turning these NixOS areas off changes nothing: ${names (failingOff nixosAreas nixosOff)}" (failingOff nixosAreas nixosOff == []);
    assert written "gates" "turning these home areas on changes nothing: ${names (failing homeOffByDefault homeOn)}" (failing homeOffByDefault homeOn == []);
    assert written "gates" "turning these NixOS areas on changes nothing: ${names (failing nixosOffByDefault nixosOn)}" (failing nixosOffByDefault nixosOn == []);
      pkgs.writeText "module-sets-gates-evaluate" (builtins.unsafeDiscardStringContext (
        homeDrv [dots.homeModules.default {dots = off homeAreas;}]
        + homeDrv [dots.homeModules.default {dots = on homeOffByDefault;}]
        + (nixos [dots.nixosModules.default {dots = off nixosAreas;}]).config.system.build.toplevel.drvPath
        + (nixos [dots.nixosModules.default {dots = on nixosOffByDefault;}]).config.system.build.toplevel.drvPath
      ));

  # Options that moved into the `dots.*` namespace keep their old names for a release:
  # a host written before the move still works, and is told, in a build warning, what to
  # rename. Each old name is set to a harmless value and must land on the new one, and
  # must produce a warning that names both. Setting the new names produces none.
  module-sets-renames = let
    renamed = [
      {
        old = ["dank" "settingsState"];
        value = {testState = true;};
      }
      {
        old = ["dank" "settingsOverlayKeys"];
        value = ["testOverlayKey"];
      }
      {
        old = ["dank" "settingsOverlay"];
        value = {controlCenterWidgets = ["x"];};
      }
      {
        old = ["dank" "curatedMenu" "entries"];
        value = [];
      }
      {
        old = ["programs" "vscode" "workspaces" "dir"];
        value = "/srv/workspaces";
      }
      {
        old = ["programs" "vscode" "profileUiState" "enable"];
        value = true;
      }
      {
        old = ["programs" "vscode" "profileUiState" "seed"];
        value = true;
      }
      {
        old = ["programs" "vscode" "profileUiState" "filesContainer"];
        value = "workbench.views.service.sidebar.4337fe0b-3e0d-40ce-9701-c62f345cfd7a"; # the value dots sets itself: equal definitions merge
      }
    ];
    # The new path: `dank.*` -> `dots.dank.*`, `programs.vscode.*` -> `dots.vscode.*`.
    newOf = old:
      if lib.take 2 old == ["programs" "vscode"]
      then ["dots" "vscode"] ++ lib.drop 2 old
      else ["dots"] ++ old;
    dotted = lib.concatStringsSep ".";
    configOf = r: home [dots.homeModules.default (lib.setAttrByPath r.old r.value)];
    configNew = r: home [dots.homeModules.default (lib.setAttrByPath (newOf r.old) r.value)];
    mentions = r: c: lib.any (w: lib.hasInfix "`${dotted r.old}'" w && lib.hasInfix "`${dotted (newOf r.old)}'" w) c.warnings;
    silent = c: !(lib.any (w: lib.hasInfix "has been renamed" w) c.warnings);
    # Some of these merge with values dots sets itself, so a set value must be contained in the result, not equal to it.
    landed = r: let
      got = lib.attrByPath (newOf r.old) null (configOf r);
    in
      if builtins.isAttrs r.value
      then lib.all (k: got ? ${k}) (lib.attrNames r.value)
      else if builtins.isList r.value
      then lib.all (x: lib.elem x got) r.value
      else got == r.value;
    notLanding = lib.filter (r: !(landed r)) renamed;
    notWarning = lib.filter (r: !(mentions r (configOf r))) renamed;
    newWarns = lib.filter (r: !(silent (configNew r))) renamed;
  in
    assert written "renames" "these old names do not reach the new option: ${toString (map (r: dotted r.old) notLanding)}" (notLanding == []);
    assert written "renames" "these old names do not warn, or the warning lacks one of the two names: ${toString (map (r: dotted r.old) notWarning)}" (notWarning == []);
    assert written "renames" "setting the new name still warns for: ${toString (map (r: dotted r.old) newWarns)}" (newWarns == []);
      pkgs.writeText "module-sets-renames-evaluate" "ok";
}
