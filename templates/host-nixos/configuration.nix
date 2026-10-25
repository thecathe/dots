# The machine itself. Everything shared comes from dots.nixosModules.default;
# add here only what is specific to this machine.
{inputs, ...}: {
  imports = [inputs.dots.nixosModules.default];

  networking.hostName = "NEW_HOST";
  networking.networkmanager.enable = true;

  users.users.NEW_USER = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel"];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # The NixOS release this machine was first installed with: it fixes the
  # defaults for stateful data. Leave it as it is after the first install.
  system.stateVersion = "26.05";
}
