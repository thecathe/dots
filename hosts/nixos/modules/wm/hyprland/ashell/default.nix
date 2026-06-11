{ pkgs, ... }:

{
  programs.ashell = {
    enable = true;
    systemd.enable = true;

    ## https://malpenzibo.github.io/ashell/docs/configuration/full_config
    ## https://mynixos.com/home-manager/option/programs.ashell.settings
    settings = {
      modules = {
        left = [
          "Workspaces"
          # "Updates"
          "appLauncher"
        ];
        center = [
          "Window Title"
        ];
        right = [
          "SystemInfo"
          # "MediaPlayer"
          "Tray"
          [
            "Tempo"
            "Clock"
            "Privacy"
            "Settings"
          ]
        ];
      };

      settings = {
        indicators = [
          "IdleInhibitor"
          "PowerProfile"
          "Audio"
          "Microphone"
          "Bluetooth"
          "Network"
          "Vpn"
          "Battery"
          "Brightness"
        ];
      };

      appearance = {
        sclae_factor = 1.5;
      };

      window_title = {
        mode = "Class";
        truncate_title_after_length = 100;
      };

      # system-info = {
      #   indicators = [
      #     "Cpu"
      #     "Memory"
      #     "Temperature"
      #     {
      #       disk = "/home/cathe";
      #       name = "cathe";
      #     }
      #   ];
      #   interval = 5;

      #   cpu = {
      #     warn_threshold = 60;
      #     alert_threshold = 80;
      #   };

      #   memory = {
      #     warn_threshold = 75;
      #     alert_threshold = 85;
      #   };

      #   temperature = {
      #     warn_threshold = 75;
      #     alert_threshold = 85;
      #   };
      # };

      tempo = {
        ## https://docs.rs/chrono/latest/chrono/format/strftime/index.html
        clock_format = "%a %d %b %R";
        weather_location = {
          City = "Rome";
        };
        weather_indicator = "Icon";
      };

      workspaces = {
        visibility_mode = "All";
        group_by_monitor = false;
        enable_workspace_filling = true;
      };
    };
  };
}
