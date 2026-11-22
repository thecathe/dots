# Profiles: named bundles of settings, each behind `dots.profile.<name>.enable`
# (off by default), so a host turns on a whole suite with one line instead of
# repeating it.
#
# Two rules every profile here keeps:
#  - A single value it sets (a boolean, a string, a number) is a `lib.mkDefault`,
#    so a host's own assignment wins without `mkForce`.
#  - A list it adds to (packages, groups) is NOT a `mkDefault`: a list default is
#    replaced whole by any ordinary definition, so one package a host adds would
#    silently drop the profile's list. Lists merge instead; a host that wants less
#    turns the profile off and copies what it wants.
#
# Profiles layer: a building block (`base`, ...) holds settings, and a role (a
# later `desktop`, `laptop`, ...) is a profile that only turns building blocks on,
# with `lib.mkDefault` too, so a host can take a role and still switch one of its
# blocks off:
#
#   config = lib.mkIf config.dots.profile.desktop.enable {
#     dots.profile.base.enable = lib.mkDefault true;
#   };
{...}: {
  imports = [
    ./base.nix
    ./gnome.nix
    ./gaming.nix
  ];
}
