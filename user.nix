{ pkgs, ... }:

let name = "test";
  username= "";
  email =""; in
{

  name= name;
  username= username;
  email =email;
  theme= {
    zsh= "agnoster";
  };
submodule= {
    isNormalUser = true;
    description = name;
    extraGroups = [ "networkmanager" "wheel" ];
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
      lutris
      libappimage
#      wine64Packages.stableFull_11
winetricks
wine64
wine64Packages.wayland
      bottles

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
  }