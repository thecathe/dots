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
    ./nix-your-shell.nix
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
    ./devlog
    ./opam
    ./globalprotect
    ./dictation
    ./flameshot
    ./zathura # epub reader?
    ./navi # cheatsheets, incl. keyboard shortcuts (navi/cheats)
    ./repos # the `repos` CLI; with DMS, the repositories bar menu (dank/repos-menu.nix)
    ./services # the `services` CLI over dots.services (the services bar menu is dank/services-menu.nix)
    ./rebuild # the `rebuild` and `rebuild-pinned` aliases, for a machine built from a hosts flake
    ./profiles # dots.profile.<name>.enable: named bundles, off by default
  ];

  # options.myConfig.onto-nvimPlugin.enable = lib.mkEnableOption "onto nvim plugin";

  # Every area of this set has a `dots.<area>.enable` switch: turn one off to leave that
  # area out (a laptop without the desktop shell, say). Most are on by default. Off by
  # default are the areas that are personal or reach beyond the machine (claude,
  # obsidian) and those that were always opt-in (vscode, dictation, globalprotect,
  # repos, rebuild), each with its own `enable`; devlog is gated by its clone directory, and
  # this set turns vscode on. flameshot is on by default. The `services` command is on
  # wherever there is a dots.services entry (dots.servicesCli.enable).
  options.dots.packages.enable = lib.mkEnableOption "dots' general-purpose package list (the tools in home.packages below)" // {default = true;};

  config = {
    dots.user.name = lib.mkDefault config.home.username;
    dots.vscode.enable = lib.mkDefault true;

    # dots.services CLIs (modules/shared/services.nix), then the rest.
    home.packages =
      config.dots.servicesPackages
      ++ lib.optionals config.dots.packages.enable (with pkgs; [
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
