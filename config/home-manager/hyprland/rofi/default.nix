{ pkgs, ... }:
{
  # https://mynixos.com/options/programs.rofi
  # https://home-manager-options.extranix.com/?query=programs.rofi
  # https://wiki.nixos.org/wiki/Rofi
  programs.rofi = {
    enable = true;
    theme = "sidebar";
    font = "sans-serif";
    package = pkgs.rofi;
    modes = [
      "drun"
      "run"
      "window"
      "ssh"
    ];
    extraConfig = {
      show-icons = true;
    };
  };
}
