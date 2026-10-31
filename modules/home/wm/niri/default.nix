{
  pkgs,
  lib,
  ...
}: {
  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    extraConfig = lib.mkMerge [
      (builtins.readFile ./config.kdl)
      # DMS's display settings GUI applies mode/position/scale/transform live over
      # IPC, but anything it can only express in KDL (the per-output `layout {}`
      # overrides, e.g. a portrait monitor's 100% default column width) goes to
      # ~/.config/niri/dms/outputs.kdl, which niri only reads if it is included.
      # DMS's own "Setup" button would add this line itself, but fails because
      # config.kdl is a read-only store symlink. The path is relative (and has to
      # stay so: DMS greps for the literal `"dms/outputs.kdl"` to decide whether
      # the include exists); niri resolves it against the config's own location,
      # not the symlink target. optional=true since only hosts that run DMS's
      # display GUI have the file.
      #
      # mkAfter puts it below any host `output` block: niri uses the first block
      # that matches an output's name, without merging, so a host's declarative
      # block (e.g. hosts/nixos' DP-1 with VRR) must come first to win over the
      # GUI-generated one.
      (lib.mkAfter ''
        include optional=true "dms/outputs.kdl"
      '')
    ];
  };

  # programs.alacritty.enable = true; # ~ changed to kitty ~Super+T in the default setting (terminal)~~
  # programs.fuzzel.enable = true; # replaced by DMS's own Spotlight launcher, Mod+Space (see config.kdl)
  programs.swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
  # programs.waybar = {
  #   enable = true; # launch on startup in the default setting (bar)
  #   settings = {
  #     mainBar = {
  #       height = 30;
  #       spacing = 4;

  #       "modules-left" = ["niri/workspaces"];
  #       "modules-center" = ["niri/window"];
  #       "modules-right" = [
  #         "pulseaudio"
  #         "network"
  #         "backlight"
  #         "battery"
  #         "clock"
  #         "tray"
  #         "custom/power"
  #       ];

  #       "niri/workspaces" = {};
  #       "niri/window" = {
  #         "max-length" = 50;
  #       };

  #       clock = {
  #         "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
  #         "format-alt" = "{:%Y-%m-%d}";
  #       };

  #       tray = {
  #         spacing = 10;
  #       };

  #       backlight = {
  #         format = "{percent}% {icon}";
  #         "format-icons" = ["" "" "" "" "" "" "" "" ""];
  #       };

  #       battery = {
  #         states = {
  #           warning = 30;
  #           critical = 15;
  #         };
  #         format = "{capacity}% {icon}";
  #         "format-charging" = "{capacity}% ";
  #         "format-plugged" = "{capacity}% ";
  #         "format-icons" = ["" "" "" "" ""];
  #       };

  #       network = {
  #         "format-wifi" = "{essid} ({signalStrength}%) ";
  #         "format-ethernet" = "{ipaddr}/{cidr} ";
  #         "format-linked" = "{ifname} (No IP) ";
  #         "format-disconnected" = "Disconnected ⚠";
  #       };

  #       pulseaudio = {
  #         format = "{volume}% {icon} {format_source}";
  #         "format-muted" = " {format_source}";
  #         "format-source" = "{volume}% ";
  #         "format-source-muted" = "";
  #         "format-icons" = {
  #           default = ["" "" ""];
  #         };
  #         "on-click" = "pavucontrol";
  #       };

  #       "custom/power" = {
  #         format = "⏻ ";
  #         tooltip = false;
  #         menu = "on-click";
  #         "menu-file" = "$HOME/.config/waybar/power_menu.xml";
  #         "menu-actions" = {
  #           shutdown = "shutdown";
  #           reboot = "reboot";
  #           suspend = "systemctl suspend";
  #           hibernate = "systemctl hibernate";
  #         };
  #       };
  #     };
  #   };
  # };

  # Referenced by the "custom/power" module above (menu-file). Without this,
  # clicking the power icon throws on the missing file and kills waybar.
  # xdg.configFile."waybar/power_menu.xml".text = ''
  #   <?xml version="1.0" encoding="UTF-8"?>
  #   <interface>
  #     <object class="GtkMenu" id="power-menu">
  #       <child>
  #         <object class="GtkMenuItem" id="shutdown">
  #           <property name="visible">True</property>
  #           <property name="can-focus">False</property>
  #           <property name="label" translatable="yes">Shutdown</property>
  #         </object>
  #       </child>
  #       <child>
  #         <object class="GtkMenuItem" id="reboot">
  #           <property name="visible">True</property>
  #           <property name="can-focus">False</property>
  #           <property name="label" translatable="yes">Reboot</property>
  #         </object>
  #       </child>
  #       <child>
  #         <object class="GtkMenuItem" id="suspend">
  #           <property name="visible">True</property>
  #           <property name="can-focus">False</property>
  #           <property name="label" translatable="yes">Suspend</property>
  #         </object>
  #       </child>
  #       <child>
  #         <object class="GtkMenuItem" id="hibernate">
  #           <property name="visible">True</property>
  #           <property name="can-focus">False</property>
  #           <property name="label" translatable="yes">Hibernate</property>
  #         </object>
  #       </child>
  #     </object>
  #   </interface>
  # '';
  # No notification daemon here on purpose: DMS is the notification server (popups,
  # history behind the bar's bell). A second daemon such as mako is D-Bus-activated
  # by the first notification at login, a few seconds before DMS has claimed
  # org.freedesktop.Notifications, and then keeps the name for the whole session.
  services.polkit-gnome.enable = true; # polkit
  home.packages = with pkgs; [
    swaybg # wallpaper
  ];
}
