# Profiles for home-manager: named bundles behind `dots.profile.<name>.enable`, off
# by default, with the same two rules as the NixOS ones (modules/nixos/profiles):
# a single value is a `lib.mkDefault`, so a host's own assignment wins; a list is
# not, so it merges with a host's.
#
# A NixOS profile and the home profile of the same name are separate switches (the
# home set must work without NixOS, and the NixOS set without home-manager), so a
# NixOS host that wants both turns on both.
{...}: {
  imports = [
    ./base.nix
    ./gnome.nix
  ];
}
