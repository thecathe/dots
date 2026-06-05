# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules/system
  ];

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  users.users.cathe = {
    isNormalUser = true;
    description = "cathe";
    extraGroups = [
      "networkmanager"
      "wheel"
      "samba"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    # inputs.nixpkgs.follows = "nixpkgs";
  };

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.supportedFilesystems = [ "ntfs" ];
  fileSystems =
    let
      ntfs-drives = [
        "/mnt/data"
        "/mnt/archive"
      ];
    in
    lib.genAttrs ntfs-drives (path: {
      options = [ "uid=1000" ];
    });

  # Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "*-*-* 21:00:00";
    options = "--delete-older-than 7d";
};
nix.settings = { keep-outputs = true;
  };

  networking.hostName = "nixos"; # Define your hostname.
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

  # Internal Drives
  services.udisks2.enable = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  hardware.nvidia = {
    videoAcceleration = true;

    #    prime = {
    #      offload = {
    #        enable = true;
    #	enableOffloadCmd = true;
    #      };
    #      nvidiaBusId = "PCI:43@0:0:0";
    #    };

    # Modesetting is required (for wayland).
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    # Configure keymap in X11
    xkb = {
      layout = "gb";
      variant = "";
    };

    # Load nvidia driver for Xorg and Wayland
    videoDrivers = [
      "modesetting"
      "nvidia"
    ];
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

  # nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.command-not-found.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    ntfs3g
    autoconf
    git
    zsh
    zsh-nix-shell
    tmux
    xplr
    rmpc

    fzf
    gh

    nix
    nixd
    nixfmt
    alejandra
    nix-search-cli
    nix-index

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

    ## https://wiki.hypr.land/Useful-Utilities/Must-have/
    # swaynotificationcenter
    wireplumber
    noto-fonts

    ## for thumnails
    ffmpeg-headless
    ffmpegthumbnailer
    gdk-pixbuf

    # teams-for-linux

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
