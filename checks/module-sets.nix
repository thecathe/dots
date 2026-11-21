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

  home = modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [base] ++ modules;
    }).config;

  homeDrv = modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [base] ++ modules;
    }).activationPackage.drvPath;

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
}
