{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nautilus
  ];
  services.gvfs.enable = true;
  # services.udisks2.enable = true;
}
