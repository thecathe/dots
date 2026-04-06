{ pkgs, ... }:

{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  imports = [
    ./user.nix
  ];
}
