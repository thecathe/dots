{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../shared/identity.nix
    ../shared/services.nix
    ./nixd.nix
    ./wm
    ./dank
    ./wallpaper
    ./music
    ./latex.nix
    ./terminfo.nix
    ./git
    ./nvim
    ./stylix
    ./shell
    ./firefox
    # ./hyprland
    ./vscode
    ./obsidian
    ./claude
    ./opam
    ./globalprotect
    ./dictation
    ./zathura # epub reader?
    ./navi # cheatsheets, incl. keyboard shortcuts (navi/cheats)
  ];

  # options.myConfig.onto-nvimPlugin.enable = lib.mkEnableOption "onto nvim plugin";
  config = {
    dots.user.name = lib.mkDefault config.home.username;
    dots.vscode.enable = lib.mkDefault true;

    # dots.services CLIs (modules/shared/services.nix), then the rest.
    home.packages =
      config.dots.servicesPackages
      ++ (with pkgs; [
        ## essential
        wget
        fzf

        ## nix
        nix
        nixfmt
        nixd # nix language server (used by both neovim and vscode)
        alejandra # nix formatter, also invoked by nixd itself

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
        audacity_3

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
      ]);
  };
}
