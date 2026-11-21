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
  # Every area of a set has a `dots.<area>.enable`, on by default. For each: what
  # is true of a configuration when the area is on and false when it is off. Cheap
  # to read (no derivation is evaluated), and each one is something a host would
  # notice. The areas that were already opt-in (their switch is off by default,
  # and they have their own checks) are named so that a new switch has to be
  # added to one list or the other. (devlog has no switch: a clone directory gates it.)
  hasPackage = name: pkgsList: lib.any (p: lib.getName p == name) pkgsList;
  homeAreas = {
    dank = c: c.programs.dank-material-shell.enable;
    firefox = c: c.programs.firefox.enable;
    git = c: c.programs.git.enable;
    navi = c: c.programs.navi.enable;
    nvim = c: c.programs.neovim.enable;
    obsidian = c: c.programs.obsidian.enable;
    shell = c: c.programs.zsh.enable;
    zathura = c: c.programs.zathura.enable;
    nixYourShell = c: c.programs.nix-your-shell.enable;
    niri = c: c.wayland.windowManager.niri.enable;
    claude = c: c.programs.claude-code.enable;
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
  homeOptIn = ["vscode" "dictation" "flameshot" "globalprotect" "repos"];

  nixosAreas = {
    claude = c: hasPackage "claude-code" c.environment.systemPackages;
    direnv = c: c.programs.direnv.enable;
    firefox = c: c.programs.firefox.enable;
    # stylix adds fonts of its own, so look for one only dots' list has.
    fonts = c: lib.any (p: lib.hasInfix "mononoki" (toString p)) c.fonts.packages;
    git = c: c.programs.git.enable;
    nautilus = c: c.services.gvfs.enable;
    nixLd = c: c.programs.nix-ld.enable;
    niri = c: c.programs.niri.enable;
    stylix = c: c.stylix.enable;
    tailscale = c: c.services.tailscale.enable;
    terminfo = c: lib.any (p: lib.hasInfix "-kitty-" (toString p) && lib.hasSuffix "-terminfo" (toString p)) c.environment.systemPackages;
    vscode = c: hasPackage "vscode" c.environment.systemPackages;
    zsh = c: c.programs.zsh.enable;
    media = c: hasPackage "strawberry" c.environment.systemPackages;
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
    moved = home [dots.homeModules.default {dots.checkout = "/srv/dots";}];
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
    names = xs: toString xs;
  in
    assert written "gates" "the home switches are ${names homeSwitches}, the tests and opt-ins cover ${names (sortNames (lib.attrNames homeAreas ++ homeOptIn))}" (homeSwitches == sortNames (lib.attrNames homeAreas ++ homeOptIn));
    assert written "gates" "the NixOS switches are ${names nixosSwitches}, the tests and opt-ins cover ${names (sortNames (lib.attrNames nixosAreas ++ nixosOptIn))}" (nixosSwitches == sortNames (lib.attrNames nixosAreas ++ nixosOptIn));
    assert written "gates" "these home areas are not on by default: ${names (failing homeAreas (_: alone))}" (failing homeAreas (_: alone) == []);
    assert written "gates" "these NixOS areas are not on by default: ${names (failing nixosAreas (_: nixosAlone.config))}" (failing nixosAreas (_: nixosAlone.config) == []);
    assert written "gates" "turning these home areas off changes nothing: ${names (failingOff homeAreas homeOff)}" (failingOff homeAreas homeOff == []);
    assert written "gates" "turning these NixOS areas off changes nothing: ${names (failingOff nixosAreas nixosOff)}" (failingOff nixosAreas nixosOff == []);
      pkgs.writeText "module-sets-gates-evaluate" (builtins.unsafeDiscardStringContext (
        homeDrv [dots.homeModules.default {dots = off homeAreas;}]
        + (nixos [dots.nixosModules.default {dots = off nixosAreas;}]).config.system.build.toplevel.drvPath
      ));
}
