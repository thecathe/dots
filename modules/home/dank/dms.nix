{
  inputs,
  pkgs,
  ...
}: {
  programs.dank-material-shell = {
    enable = true;

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)

    # dank packages
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;

    # niri
    # niri = {
    #   enableKeybinds = true;
    #   enableSpawn = true;
    # };

    settings = {
      theme = "dark";
      dynamicTheming = true;
      # Add any other settings here
    };

    session = {
      isLightMode = false;
      # Add any other session state settings here
    };

    clipboardSettings = {
      maxHistory = 25;
      maxEntrySize = 5242880;
      autoClearDays = 1;
      clearAtStartup = true;
      disabled = false;
      disableHistory = false;
      disablePersist = true;
    };

    # systemd service for auto-start
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
  };
}
