{pkgs, ...}: {
  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    extraConfig = builtins.readFile ./config.kdl;
  };

  # programs.alacritty.enable = true; # ~ changed to kitty ~Super+T in the default setting (terminal)~~
  programs.fuzzel.enable = true; # Super+D in the default setting (app launcher)
  programs.swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
  programs.waybar = {
    enable = true; # launch on startup in the default setting (bar)
    settings = {
      mainBar = {
        height = 30;
        spacing = 4;

        "modules-left" = ["niri/workspaces"];
        "modules-center" = ["niri/window"];
        "modules-right" = [
          "pulseaudio"
          "network"
          "backlight"
          "battery"
          "clock"
          "tray"
          "custom/power"
        ];

        "niri/workspaces" = {};
        "niri/window" = {
          "max-length" = 50;
        };

        clock = {
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          "format-alt" = "{:%Y-%m-%d}";
        };

        tray = {
          spacing = 10;
        };

        backlight = {
          format = "{percent}% {icon}";
          "format-icons" = ["" "" "" "" "" "" "" "" ""];
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          "format-charging" = "{capacity}% ";
          "format-plugged" = "{capacity}% ";
          "format-icons" = ["" "" "" "" ""];
        };

        network = {
          "format-wifi" = "{essid} ({signalStrength}%) ";
          "format-ethernet" = "{ipaddr}/{cidr} ";
          "format-linked" = "{ifname} (No IP) ";
          "format-disconnected" = "Disconnected ⚠";
        };

        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          "format-muted" = " {format_source}";
          "format-source" = "{volume}% ";
          "format-source-muted" = "";
          "format-icons" = {
            default = ["" "" ""];
          };
          "on-click" = "pavucontrol";
        };

        "custom/power" = {
          format = "⏻ ";
          tooltip = false;
          menu = "on-click";
          "menu-file" = "$HOME/.config/waybar/power_menu.xml";
          "menu-actions" = {
            shutdown = "shutdown";
            reboot = "reboot";
            suspend = "systemctl suspend";
            hibernate = "systemctl hibernate";
          };
        };
      };
    };
  };

  # Referenced by the "custom/power" module above (menu-file). Without this,
  # clicking the power icon throws on the missing file and kills waybar.
  xdg.configFile."waybar/power_menu.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <object class="GtkMenu" id="power-menu">
        <child>
          <object class="GtkMenuItem" id="shutdown">
            <property name="visible">True</property>
            <property name="can-focus">False</property>
            <property name="label" translatable="yes">Shutdown</property>
          </object>
        </child>
        <child>
          <object class="GtkMenuItem" id="reboot">
            <property name="visible">True</property>
            <property name="can-focus">False</property>
            <property name="label" translatable="yes">Reboot</property>
          </object>
        </child>
        <child>
          <object class="GtkMenuItem" id="suspend">
            <property name="visible">True</property>
            <property name="can-focus">False</property>
            <property name="label" translatable="yes">Suspend</property>
          </object>
        </child>
        <child>
          <object class="GtkMenuItem" id="hibernate">
            <property name="visible">True</property>
            <property name="can-focus">False</property>
            <property name="label" translatable="yes">Hibernate</property>
          </object>
        </child>
      </object>
    </interface>
  '';
  services.mako.enable = true; # notification daemon
  services.swayidle.enable = true; # idle management daemon
  services.polkit-gnome.enable = true; # polkit
  home.packages = with pkgs; [
    swaybg # wallpaper
  ];
}
