{ pkgs, ... }:

let
  userJSON = builtins.fromJSON (builtins.readFile "/home/cathe/dots/user.json");
  name = userJSON.name;
  username = userJSON.username;
  email = userJSON.email;
  hostname = userJSON.hostname;
  home = "/home/" + username;
in
{
  name = name;
  username = username;
  email = email;
  hostname = hostname;
  home = home;

  configs = {
    zsh = {
      theme = "agnoster";
      options = [
        "HIST_IGNORE_DUPS"
        "HIST_IGNORE_ALL_DUPS"
        "HIST_SAVE_NO_DUPS"
        "HIST_FIND_NO_DUPS"
        "HIST_IGNORE_SPACE"
        "APPENDHISTORY"
        "SHARE_HISTORY"
        "HIST_FCNTL_LOCK"
      ];
    };
  };

  user = {
    users.users."${username}" = {
      isNormalUser = true;
      description = name;
      extraGroups = [
        "networkmanager"
        "wheel"
        "samba"
      ];
      packages = with pkgs; [
        wget

        linuxKernel.packages.linux_zen.nvidia_x11_vulkan_beta_open
        # linuxKernel.packages.linux_zen.nvidia_x11_vulkan_beta
        egl-wayland

        zsh
        fzf
        neovim
        #    vimPlugins.coc-nvim
        powerline
        powerline-go
        powerline-fonts
        powerline-symbols

        tmux
        abduco
        dvtm

        git
        gh

        flatpak
        libappimage

        # lutris

        #      wine64Packages.stableFull_11

        # for battlenet: https://wiki.nixos.org/wiki/Battle.net
        (wineWow64Packages.full.override {
          wineRelease = "staging";
          mingwSupport = true;
        })
        winetricks

        wine64
        # bottles

        protontricks

        nix
        #  nix-search-cli
        #  nix-index
        #  nix-diff
        # ocaml
        # opam
        # racket
        # postgresql
        # go
        # python3
        # beam28Packages.erlang
        # erlang-language-platform
        # jdk8
        # ghc

        # miktex
        ansi

        alacritty
        hyprland
        sway
        swaylock
        waylock
        quickshell
        mutagen
        slurp
        eww

        discord
        obsidian

        #      steam
        #      steamcmd
        #     steam-run
        # haskellPackages.battlenet

        ffmpeg
        obs-studio
        satty

        kittysay
        # neofetch
        fastfetch
        # hyfetch
        # honeyfetch

        #teams
        vscode
        onedrive

        rmpc

      ];
    };
  };
}
