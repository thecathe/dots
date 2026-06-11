{ pkgs, ... }:

## https://wiki.nixos.org/wiki/Thumbnails#Enable_3D_Model_Thumbnails
{
  environment.systemPackages = with pkgs; [
    f3d
  ];
}
