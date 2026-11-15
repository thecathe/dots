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
# portal. Here that is xdg-desktop-portal-gnome asking niri over
# org.gnome.Shell.Screenshot, so nothing else (grim, slurp) has to be installed.
# The overlay is a frameless full-screen window sized to one output.
#
# Known rough edges (worked out from Flameshot's source and niri's documented
# behaviour, not yet seen on a real desktop; see the devlog entry
# dots/flameshot.md):
#   - With more than one output Flameshot first opens a window with a preview of
#     each and waits for a click. `captureActiveMonitor` would skip it but is
#     refused on Wayland, and `flameshot gui` has no output option.
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

  # Included from niri's config.kdl the way dictation's binds are. The bind
  # replaces config.kdl's own `Print { screenshot; }` (niri replaces a conflicting
  # bind from an included file instead of reporting an error), and the window
  # rule is appended to the main file's rules.
  #   repeat=false  holding the key would otherwise start a capture again and again
  # allow-inhibiting is left at its default (true), so a game or remote desktop
  # that asks niri to stop processing shortcuts also stops this.
  bindLines =
    [
      ''${cfg.bind} repeat=false hotkey-overlay-title="Screenshot: select, draw, pin (Flameshot)" { spawn "${flameshot}" "gui"; }''
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

  config = lib.mkIf cfg.enable {
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
  };
}
