{ pkgs, config, ... }:

{
  # https://mynixos.com/home-manager/options/programs.firefox
  programs.firefox = {
    enable = true;
    profiles = import ./profiles.nix { inherit pkgs; };
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    policies = {
      # DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true;
      # ExtensionSettings =
      #   let
      #     moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
      #   in
      #   {
      #     # For blocking all extensions (except those specified later)
      #     # "*".installation_mode = "blocked";

      #     "uBlock0@raymondhill.net" = {
      #       install_url = moz "ublock-origin";
      #       installation_mode = "force_installed";
      #       updates_disabled = true;
      #     };
      #   };
    };
    # configPath = "./mozilla/firefox";
  };
}
