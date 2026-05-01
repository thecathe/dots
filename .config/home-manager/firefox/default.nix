{ pkgs, config, ... }:

{
  # https://mynixos.com/home-manager/options/programs.firefox
  programs.firefox = {
    enable = true;
    profiles = import ./profiles.nix { inherit pkgs; };
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    # configPath = "./mozilla/firefox";
  };
}
