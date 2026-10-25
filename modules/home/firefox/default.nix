{
  config,
  lib,
  ...
}: {
  options.dots.firefox.profile = lib.mkOption {
    type = lib.types.str;
    default = config.home.username;
    defaultText = lib.literalExpression "config.home.username";
    description = ''
      The main Firefox profile's name, which is also its directory: changing it
      on a machine that already has a profile starts a new, empty one.
    '';
  };

  # https://mynixos.com/home-manager/options/programs.firefox
  config.programs.firefox = {
    enable = true;
    profiles = import ./profiles.nix config.dots.firefox.profile;
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
