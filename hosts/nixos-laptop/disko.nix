# Declarative disk layout, applied by `disko` during install via nixos-anywhere.
# `device` is a placeholder - confirm the real disk with `lsblk` on the actual
# laptop before running the install, and update it here first.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            settings.allowDiscards = true;
            # Written once in the live install session (see default.nix's
            # comment above its hardware-configuration.nix import for the
            # full install-order caveat), never committed - consumed by
            # disko during formatting only.
            passwordFile = "/tmp/secret.key";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
