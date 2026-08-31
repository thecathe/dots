{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./wm
    ./dank
    ./music
    ./git
    ./nvim
    ./stylix
    ./shell
    ./firefox
    # ./hyprland
    ./vscode
    ./obsidian
    ./claude
    ./zathura # epub reader?
    ./navi # commadn cheatsheet tool
  ];

  # options.myConfig.onto-nvimPlugin.enable = lib.mkEnableOption "onto nvim plugin";
  config = {
    home.packages = with pkgs; [
      ## essential
      wget
      fzf

      ## nix
      nix
      nixfmt

      ## packages
      flatpak # # installer
      libappimage # # appimage

      ## git
      git
      gh
      gource # # timelapse

      ## terminal
      tmux # # multiplexer
      # abduco ## sessions, kitty?
      # dvtm ## tilling, kitty?

      ## audio tools
      ffmpeg
      obs-studio # # screen recording

      ## music
      rmpc # # kitty music-player?

      ## software
      audacity

      ## cloud storage
      onedrive

      ## misc
      satty # # screenshot tool
      ansi # # get ansi escape sequences
      rpi-imager # # rasberry-pi headless config
      pomodoro # # timer

      ## silly
      kittysay
      fastfetch
    ];
  };
}
