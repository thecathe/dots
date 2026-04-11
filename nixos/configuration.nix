# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  lib,
  pkgs,
  inputs,
  #      thenixuser ? import /home/cathe/dots/user.nix
  ...
}:

let
  thenixuser = import /home/cathe/dots/user.nix { inherit pkgs; };
  thenvidia = import (thenixuser.home + "/dots/nixos/nvidia.nix") { inherit config; };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
    thenixuser.user
    ./programs
    # ./modules/network-sharing
    ./modules/thumbnails

    #      <nixos-hardware/common/cpu/amd>
    #      <nixos-hardware/common/gpu/nvidia/ada-lovelace>
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  # Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "*-*-* 21:00:00";
    options = "--delete-older-than 7d";
  };

  networking.hostName = thenixuser.hostname; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Internal Drives
  services.udisks2.enable = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = thenvidia.videoDrivers;
  hardware.nvidia = thenvidia.nvidia;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    ntfs3g
    autoconf

    neovim
    # vimPlugins.coc-nvim

    git
    zsh
    zsh-nix-shell
    tmux
    xplr
    rmpc

    fzf
    gh

    nix
    nixfmt
    nix-search-cli
    nix-index
    # direnv

    flatpak
    libappimage

    wine64
    wine64Packages.wayland
    wine-staging
    winetricks
    protonup-qt
    protontricks

    ffmpeg
    vlc
    samba
    avahi

    linuxKernel.packages.linux_zen.nvidia_x11_vulkan_beta_open
    # linuxKernel.packages.linux_zen.nvidia_x11_vulkan_beta

    egl-wayland
    alacritty
    kitty
    hyprland
    # waybar
    # waybar-lyric
    hyprpaper
    ags
    sway
    swaylock
    hypridle

    expat # required by fontconfig?
    fontconfig # required by hyprland?

    hyprlandPlugins.hy3
    # hyprlandPlugins.hyprbars # err
    hyprlandPlugins.hyprsplit
    # hyprlandPlugins.hyprspace # err
    # hyprlandPlugins.hyprfocus # err
    # hyprlandPlugins.hyprtrails # err
    hyprlandPlugins.hypr-dynamic-cursors

    # waylock
    # quickshell ## replace waybar
    mutagen
    slurp
    eww
    rofi

    ## https://wiki.hypr.land/Useful-Utilities/Must-have/
    swaynotificationcenter
    wireplumber
    noto-fonts

    ## for thumnails
    ffmpeg-headless
    ffmpegthumbnailer
    gdk-pixbuf
  ];
  # programs.direnv.enable = true;

  # https://wiki.nixos.org/wiki/Thumbnails
  environment.pathsToLink = [
    "share/thumbnailers"
  ];

  # Powerline
  #  programs.powerline-go = {
  #    enable = true;
  #  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  # Automatic Updates
  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
  };
}
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
