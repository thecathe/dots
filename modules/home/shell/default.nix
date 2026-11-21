{lib, ...}: {
  imports = [
    ./zsh
    ./direnv.nix
    ./starship.nix
    ./tmux.nix
    ./kitty.nix
    ./zoxide.nix
  ];
  options.dots.shell.enable = lib.mkEnableOption "the shell setup (zsh, kitty, tmux, starship, zoxide, direnv)" // {default = true;};
}
