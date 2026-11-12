# Kitty's terminfo entry for every user of the machine, root included, so an
# ssh login from kitty (or `sudo -i` on the machine) finds the terminal it is
# talking to. The per-user copy in ~/.terminfo (modules/home/terminfo.nix) cannot
# reach root's own home; this lands in /run/current-system/sw/share/terminfo,
# which NixOS puts on everyone's TERMINFO_DIRS.
{pkgs, ...}: {
  environment.systemPackages = [pkgs.kitty.terminfo];
}
