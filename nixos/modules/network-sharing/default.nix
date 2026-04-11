{
  config,
  lib,
  pkgs,
  ...
}:

let
  samba = import ./samba.nix { };
  samba-wsdd = import ./samba-wsdd.nix { };
  avahi = import ./avahi.nix { };
in
{
  services = {
    samba = samba;
    samba-wsdd = samba-wsdd;
    avahi = avahi;
  };
}
