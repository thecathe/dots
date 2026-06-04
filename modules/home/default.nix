{
  pkgs,
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
