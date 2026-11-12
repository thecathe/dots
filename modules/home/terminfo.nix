# Kitty's terminfo entry (xterm-kitty) in ~/.terminfo, so a shell reached over
# ssh from kitty knows the terminal it is talking to.
#
# Kitty hands its own entry to the programs it starts (through $TERMINFO), but
# ssh forwards only $TERM. A host without the entry then cannot look the
# terminal up: zsh reports "can't find terminal definition", cannot move the
# cursor or set colours, and the line editor redraws over itself (duplicated
# characters beside autosuggestions, wrong suggestion colour). Ubuntu's base
# terminfo, for one, has no kitty entry.
#
# ~/.terminfo is on ncurses' search path by default, so this needs no
# environment variable, reaches every shell and program, and works on a host
# that is not NixOS, where nothing under /usr can be written. Linked file by file
# so other tools (tic, kitten ssh) can still add entries beside it. Root's own
# $HOME does not see it. On NixOS, modules/nixos/terminfo.nix covers root; on any
# other host `sudo apt install kitty-terminfo` (Debian, Ubuntu) does, by hand.
{pkgs, ...}: {
  home.file.".terminfo" = {
    source = "${pkgs.kitty.terminfo}/share/terminfo";
    recursive = true;
  };
}
