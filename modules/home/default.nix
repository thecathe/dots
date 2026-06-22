{
  lib,
  config,
  ...
}: {
  imports = [
    ./git
    ./nvim
    # ./stylix
    ./shell
    ./firefox
    # ./hyprland
    ./zathura
  ];

  options.myConfig.onto-nvimPlugin.enable = lib.mkEnableOption "onto nvim plugin";
}
