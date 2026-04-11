{ pkgs, input, ... }:

let
  enabled = true;
  withUWSM = false;
in
{
  # https://mynixos.com/options/programs.hyprland
  wayland.windowManager.hyprland = {
    enable = enabled;
    # Need to disable systemd integration if hyprland is enabled: https://wiki.nixos.org/wiki/Hyprland
    systemd.enable = !withUWSM;
    xwayland.enable = true;
    plugins =
      with pkgs;
      with hyprlandPlugins;
      [
        hy3
        ashell
        # hyprbars
        hyprsplit
        # hyprspace
        # hyprfocus
        # hyprtrails
        hypr-dynamic-cursors
      ];
    settings = {
      input = {
        kb_layout = "gb";
        kb_variant = "";
      };
      "$mod" = "SUPER";
      # "$terminal" = config.sysopts.terminal;
      # "$launcher" = config.sysopts.launcher;
      "$fileManager" = "nautilus";
      "$browser" = "firefox";
      windowrule = [
        # "nofocus, class:^(kitty)$"
        # "match:suppress_event maximize, class:.*"
        # "match:no_initial_focus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];
      bind = [
        ## apps
        "$mod, B, exec, firefox -p cathe"
        "$mod, Return, exec, alacritty"
        "$mod, E, exec, $fileManager"
        "$mod SHIFT, C, killactive"
        ## focus
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        # "$mod, W, exec, waybar" # idk if this would even work
        # ", Print, exec, grimblast copy area"
        # Execute Rofi with only the SUPER key
        # "$mod, Super_L, exec, pkill rofi || rofi -show drun"
        "$mod, P, exec, pkill rofi || rofi -show drun" # changed to match awesomewm

      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          ) 9
        )
      );
      ## https://wiki.nixos.org/wiki/Hyprland
      # decoration = {
      #   # shadow_offset = "0 5";
      #   # "col.shadow" = "rgba(00000099)";
      #   shadow = {
      #     offset = "0.5";
      #     color = "rgba(00000099)";
      #   };
      # };
      # Startup Apps
      exec-once = [
        "hyprpanel"
        # "waybar"
        # "ashell"
        "hypridle"
        "swaynotificationcenter"
      ];
      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];
    };
  };
  # programs.hyprland = {
  #   enable = enabled;
  #   withUWSM = withUWSM;
  #   xwayland.enable = enabled;
  #   # TODO:
  # };
  home.sessionVariables.NIXOS_OZONE_WL = # ? feels shitty
    if enabled then "1" else null;
}
