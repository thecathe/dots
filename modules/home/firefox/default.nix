{
  pkgs,
  config,
  inputs,
  ...
}:

{
  # https://mynixos.com/home-manager/options/programs.firefox
  programs.firefox = {
    enable = true;
    # Pinned ahead of the main nixpkgs input (see flake.nix's nixpkgs-firefox
    # comment) - a migrated real profile last written by Firefox 154.0.1 hit
    # NS_ERROR_FAILURE/getItem storage errors on Outlook/Microsoft sites when
    # opened with the main input's older 153.0.1. Drop this override once the
    # main nixpkgs input catches up to >=154.0.1.
    package = inputs.nixpkgs-firefox.legacyPackages.${pkgs.stdenv.hostPlatform.system}.firefox;
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
