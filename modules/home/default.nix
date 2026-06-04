{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./git
    ./nvim
    ./stylix
    ./shell
    ./firefox
    ./hyprland
  ];
}
