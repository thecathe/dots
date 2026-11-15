# Flameshot: the Print key opens a screenshot overlay where the selection can be
# resized and moved, drawn on (arrows, boxes, text, blur, ...) before anything is
# captured, and then copied, saved or pinned on the screen as a floating window.
#
# What it replaces: niri's own `Print { screenshot; }`. That UI selects a region
# but has no annotation or pinning. niri's UI stays on Shift+Print as a fallback,
# and Ctrl+Print / Alt+Print (whole screen, focused window) are untouched:
# Flameshot cannot capture a single window.
#
# The pieces:
#   the daemon  a user service running `flameshot`. The overlay and the pinned
#            windows live inside it, and so does the clipboard content on Wayland,
#            so `flameshot gui` has to reach a running daemon: started by itself
#            it would exit after the capture, and take the pins and the clipboard
#            with it.
#   a niri bind  `flameshot gui` on `bind`, added the way dictation's is (an
#            included file whose binds replace the same keys in config.kdl).
#   a niri rule  pins open floating. A pin is a window like any other to niri,
#            which would tile it; its title, "flameshot-pin", is fixed in
#            Flameshot's source (src/tools/pin/pinwidget.cpp).
#   a config file  generated from `settings`, installed read-only.
#
# How it captures (Flameshot 14): on Wayland only through the XDG screenshot
# portal; it has no other path. The overlay is a frameless full-screen window
# sized to one output.
#
# With more than one output, `wlrScreenshotPortal` is needed. By default the
# portal's Screenshot is served by xdg-desktop-portal-gnome asking niri over
# org.gnome.Shell.Screenshot, and niri 26.04's handler for that call
# (`screenshot_all_outputs`, src/niri.rs) says "FIXME: support multiple outputs"
# and `ensure!(outputs.len() == 1)`. So with two monitors every capture fails:
# niri logs "error taking a screenshot: Condition failed: outputs.len() == 1
# (2 vs 1)", the portal logs "Failed to get screenshot ... internal error", and
# 30 seconds later Flameshot's own "portal timed out" notifications arrive (seen
# on `nixos` on 2026-11-15, the first live run). One output is fine as it is.
#
# `wlrScreenshotPortal` serves only Screenshot from xdg-desktop-portal-wlr
# instead, which runs `grim` over the whole desktop (niri implements the
# wlr-screencopy protocol grim uses); the other interfaces, screencasting
# included, stay where they were. Tried in an isolated portal session against
# the two real outputs of `nixos` (a rotated 1080x1920 and a 1920x1080): both
# came back at the right size.
#
# Speed: xdg-desktop-portal-wlr runs plain `grim -- /tmp/out.png`, and grim's
# default PNG compression took about 540 ms for both outputs, half of the
# time from Print to the overlay. The portal is built with a `grim` that writes
# uncompressed PNGs (`portalPngLevel`, default 0: about 100 ms for the same
# capture; Flameshot reads the file and deletes it straight away). Measured end
# to end with `flameshot screen -n N -p` in an isolated session on `nixos`:
# about 1085/855 ms (the two outputs) at the default, 750/535 at level 1 and
# 575/355 at level 0.
#
# Flameshot then asks which output to use before every capture (a window with a
# preview of each, waiting for a click): `captureActiveMonitor` would skip that
# but is refused on Wayland, and `flameshot gui` has no output option. `screenOrder`
# skips it: `flameshot screen --edit -n N` opens the same overlay on output number
# N, and a small wrapper on the Print key looks up the focused output (the one the
# pointer is on) in `screenOrder` to find N.
#
# Known rough edges (worked out from Flameshot's source and niri's documented
# behaviour, not yet seen on a real desktop; see the devlog entry
# dots/flameshot.md):
#   - Whether niri puts the full-screen overlay on the output Flameshot asks for
#     is not known; the wrapper picks the focused output, which is also where
#     niri would put it if it ignores the request.
#   - A pin is an ordinary floating window, so it belongs to one workspace; it
#     does not follow you to the next one, and it opens centred, not where the
#     selection was.
#
# The config file is read-only. Flameshot's own settings dialog (and the colour it
# remembers having last drawn with) cannot save: the write fails quietly and the
# link survives, so a home-manager switch is never blocked by it. Change settings
# here.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.flameshot;

  iniFormat = pkgs.formats.ini {};
  configFile = iniFormat.generate "flameshot.ini" cfg.settings;

  flameshot = "${cfg.package}/bin/flameshot";

  # The niri client has to match the running compositor, so use the same package
  # the niri module installs.
  niriPackage = let
    p = config.wayland.windowManager.niri.package;
  in
    if p == null
    then pkgs.niri
    else p;

  # Print with `screenOrder` set: open Flameshot's overlay on the output the
  # pointer is on, without its output picker. Anything unexpected (niri not
  # answering, an output missing from the list) falls back to the plain
  # `flameshot gui`, which still works and asks.
  screenWrapper = pkgs.writeShellApplication {
    name = "flameshot-screen";
    runtimeInputs = [niriPackage pkgs.jq cfg.package];
    text = ''
      order=(${lib.escapeShellArgs cfg.screenOrder})
      focused=$(niri msg --json focused-output | jq -r '.name // empty' || true)
      for i in "''${!order[@]}"; do
        if [ "''${order[$i]}" = "$focused" ]; then
          exec flameshot screen --edit -n "$i"
        fi
      done
      exec flameshot gui
    '';
  };

  # xdg-desktop-portal-wlr takes its `grim` as a build input, so the faster one is
  # swapped in there; it is a plain wrapper, the same grim underneath.
  fastGrim = pkgs.writeShellScriptBin "grim" ''
    exec ${pkgs.grim}/bin/grim -l ${toString cfg.portalPngLevel} "$@"
  '';
  wlrPortal = pkgs.xdg-desktop-portal-wlr.override {grim = fastGrim;};

  # What the bind runs.
  captureCommand =
    if cfg.screenOrder == []
    then ''"${flameshot}" "gui"''
    else ''"${screenWrapper}/bin/flameshot-screen"'';

  # Included from niri's config.kdl the way dictation's binds are. The bind
  # replaces config.kdl's own `Print { screenshot; }` (niri replaces a conflicting
  # bind from an included file instead of reporting an error), and the window
  # rule is appended to the main file's rules.
  #   repeat=false  holding the key would otherwise start a capture again and again
  # allow-inhibiting is left at its default (true), so a game or remote desktop
  # that asks niri to stop processing shortcuts also stops this.
  bindLines =
    [
      ''${cfg.bind} repeat=false hotkey-overlay-title="Screenshot: select, draw, pin (Flameshot)" { spawn ${captureCommand}; }''
    ]
    ++ lib.optional (cfg.niriBind != null)
    ''${cfg.niriBind} hotkey-overlay-title="Screenshot: niri's own selector" { screenshot; }'';

  niriFile = pkgs.writeText "flameshot.kdl" ''
    // Screenshots with Flameshot (modules/home/flameshot).
    binds {
        ${lib.concatStringsSep "\n    " bindLines}
    }

    // Pinned screenshots float instead of being tiled.
    window-rule {
        match title="^flameshot-pin$"
        open-floating true
    }
  '';
in {
  options.dots.flameshot = {
    enable = lib.mkEnableOption "Flameshot, the screenshot tool on Print (select, draw on it, pin it)";

    package = lib.mkPackageOption pkgs "flameshot" {};

    bind = lib.mkOption {
      type = lib.types.str;
      default = "Print";
      example = "Mod+Shift+S";
      description = ''
        The niri key that opens Flameshot's selection overlay. Takes effect on
        hosts that use dots' niri module. If it is a key config.kdl already
        binds, this one wins.
      '';
    };

    niriBind = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Shift+Print";
      example = null;
      description = ''
        The niri key that keeps niri's own region screenshot (`screenshot`)
        reachable once `bind` has taken Print: a selector that needs nothing
        running, for when Flameshot's daemon is down. `null` leaves it unbound.
      '';
    };

    wlrScreenshotPortal = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Serve the XDG Screenshot portal from xdg-desktop-portal-wlr (which runs
        `grim`) instead of from niri. Needed on a host with more than one output:
        niri 26.04's own handler refuses to capture then, and Flameshot has no
        other way to capture on Wayland (see the top of this file). Adds the
        portal to home-manager's portal set, starts it as a user service, and
        writes the user-level `niri-portals.conf` with Screenshot pointed at it.
        That file replaces the system one rather than merging with it, so it
        repeats the rest of niri's list (gnome and gtk, with Access, FileChooser,
        Notification and Secret as they are on `nixos`); a host that sets the
        same file itself (the work laptop's `xdg.configFile`) must not turn this on.
      '';
    };

    portalPngLevel = lib.mkOption {
      type = lib.types.ints.between 0 9;
      default = 0;
      description = ''
        PNG compression level (0 to 9) of the screenshot the wlr portal takes, when
        `wlrScreenshotPortal` is on. The default grim level is 6 and takes about
        540 ms for the two outputs of `nixos`; 0 stores the pixels uncompressed (about
        100 ms, a 23 MB temporary file that Flameshot deletes once it has loaded it).
        The picture is the same at every level.
      '';
    };

    screenOrder = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["HDMI-A-1" "DP-1"];
      description = ''
        The outputs in the order Flameshot (Qt) numbers them, which follows the
        order the compositor announces them, not their position. With this set,
        Print opens the overlay straight on the output the pointer is on instead
        of asking which one: the wrapper takes the focused output's name from
        niri and passes its place in this list to `flameshot screen --edit -n`.
        An output that is not in the list gets the plain `flameshot gui` (with its
        question). To find the order on a host, run
        `flameshot screen -n 0 -p /tmp/f` and then `-n 1`, and compare the images'
        sizes with `niri msg outputs`. If the wrong output shows up later, the
        order changed (a monitor was unplugged and replugged, for instance) and
        this list is what to fix.
      '';
    };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = {};
      example = {General.showHelp = false;};
      description = ''
        Flameshot's `flameshot.ini`, as an attribute set of sections. Only what
        differs from Flameshot's own defaults needs to be here (the defaults set
        by this module can be replaced with a plain assignment). The keys are
        listed in Flameshot's `flameshot.example.ini`.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      dots.flameshot.settings.General = {
        # The daemon has nothing to show: the key starts a capture, and the DMS bar
        # has its own tray, which would otherwise gain an icon for it.
        disabledTrayIcon = lib.mkDefault true;
        # No "Flameshot is running" notification at every login.
        showStartupLaunchMessage = lib.mkDefault false;
        # What niri's screenshot did, which this replaces: the file lands in
        # ~/Pictures/Screenshots under the same name pattern, and copying to the
        # clipboard saves it too. (config.kdl's `screenshot-path` is the original.)
        savePath = lib.mkDefault "${config.home.homeDirectory}/Pictures/Screenshots";
        savePathFixed = lib.mkDefault true;
        filenamePattern = lib.mkDefault "Screenshot from %F %H-%M-%S";
        saveAfterCopy = lib.mkDefault true;
      };

      home.packages = [cfg.package];

      xdg.configFile."flameshot/flameshot.ini".source = configFile;

      systemd.user.services.flameshot = {
        Unit = {
          Description = "Flameshot: screenshot overlay and pinned screenshots";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          # The config is read at start; a changed file is a new store path, which
          # would otherwise leave the old daemon running on the old settings.
          X-Restart-Triggers = [configFile];
          # A crash on start (no display yet, a broken config) is retried a few
          # times, then stays failed and visible in `systemctl --user status`.
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          ExecStart = flameshot;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      wayland.windowManager.niri.extraConfig = ''
        include "${niriFile}"
      '';
    }

    (lib.mkIf cfg.wlrScreenshotPortal {
      # home-manager's niri module already turns xdg.portal on with only the gnome
      # portal; the frontend reads its portal definitions from that profile (the
      # NIX_XDG_DESKTOP_PORTAL_DIR it sets), so wlr's has to be added here.
      xdg.portal.enable = lib.mkDefault true;
      xdg.portal.extraPortals = [wlrPortal];
      xdg.portal.config.niri = {
        default = lib.mkDefault ["gnome" "gtk"];
        "org.freedesktop.impl.portal.Access" = lib.mkDefault ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = lib.mkDefault ["gtk"];
        "org.freedesktop.impl.portal.Notification" = lib.mkDefault ["gtk"];
        "org.freedesktop.impl.portal.Secret" = lib.mkDefault ["gnome-keyring"];
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
      };

      # Running from login, so there is nothing for D-Bus to activate on the
      # first Print. (The package also ships a unit of this name; this one in
      # ~/.config/systemd/user takes precedence.)
      systemd.user.services.xdg-desktop-portal-wlr = {
        Unit = {
          Description = "Portal service (wlroots implementation: Screenshot only here)";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.impl.portal.desktop.wlr";
          ExecStart = "${wlrPortal}/libexec/xdg-desktop-portal-wlr";
          Restart = "on-failure";
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    })
  ]);
}
