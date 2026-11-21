# The `base` profile: what any NixOS machine of this setup has, whatever it is for.
# Nix housekeeping, the boot loader, the dots user's account, networking, audio,
# graphics and Bluetooth, printing, removable drives, a few developer tweaks and a
# list of everyday command-line and desktop tools.
#
# Not here, because they are a person's choices rather than a machine's: the
# timezone, locale and keyboard layout, and anything naming another machine.
# `home-manager.*` is not here either: the set must evaluate in a plain
# `nixosSystem` without home-manager.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  options.dots.profile.base.enable = lib.mkEnableOption "the base profile: nix housekeeping, boot, the user account, networking, audio, printing and everyday tools";

  config = lib.mkIf config.dots.profile.base.enable {
    # `nixpkgs` in NIX_PATH is the pinned one, for nix-shell -p and the like.
    # The source `lib.nixosSystem` sets: it keeps nixpkgs in the system's closure, so
    # garbage collection cannot delete what NIX_PATH points at ("${pkgs.path}" would
    # copy nixpkgs a second time, and toString would drop the reference). Priority
    # 900, because nixpkgs sets its own list with mkDefault and two mkDefault lists
    # concatenate; a host's plain assignment still wins.
    nix.nixPath = lib.mkIf (config.nixpkgs.flake.source != null) (lib.mkOverride 900 ["nixpkgs=${config.nixpkgs.flake.source}"]);

    nix.gc = {
      automatic = mkDefault true;
      dates = mkDefault "*-*-* 21:00:00";
      options = mkDefault "--delete-older-than 7d";
    };
    nix.settings.keep-outputs = mkDefault true;

    system.autoUpgrade = {
      enable = mkDefault false;
      allowReboot = mkDefault false;
    };

    boot.loader.systemd-boot = {
      enable = mkDefault true;
      configurationLimit = mkDefault 15;
    };
    boot.loader.efi.canTouchEfiVariables = mkDefault true;

    # DankSearch's index and VS Code watch many files. nixpkgs already sets this
    # with mkDefault (priority 1000), so a second mkDefault would clash; 900 still
    # loses to a host's plain assignment (100).
    boot.kernel.sysctl."fs.inotify.max_user_watches" = lib.mkOverride 900 1048576;

    users.users.${config.dots.user.name} = {
      isNormalUser = mkDefault true;
      description = mkDefault config.dots.user.name;
      extraGroups = ["networkmanager" "wheel"];
    };

    networking.networkmanager.enable = mkDefault true;

    services.udisks2.enable = mkDefault true;

    hardware = {
      graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true;
      };
      bluetooth = {
        enable = mkDefault true;
        powerOnBoot = mkDefault false;
      };
    };

    services.xserver.enable = mkDefault true;

    services.printing.enable = mkDefault true;

    # Sound with PipeWire.
    services.pulseaudio.enable = mkDefault false;
    security.rtkit.enable = mkDefault true;
    services.pipewire = {
      enable = mkDefault true;
      alsa.enable = mkDefault true;
      alsa.support32Bit = mkDefault true;
      pulse.enable = mkDefault true;
    };

    # nix-index's command-not-found, in place of the channel-based one.
    programs.nix-index = {
      enable = mkDefault true;
      enableZshIntegration = mkDefault true;
    };
    programs.command-not-found.enable = mkDefault false;

    environment.systemPackages = with pkgs; [
      wget
      ntfs3g
      autoconf
      git
      zsh
      zsh-nix-shell
      tmux
      xplr
      fzf
      gh
      nix
      nixd
      nixfmt
      alejandra
      nix-search-cli
      nix-index
      neovide
      flatpak
      libappimage
      ffmpeg
      vlc
      wireplumber
      noto-fonts
    ];
  };
}
