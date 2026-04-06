{ pkgs, ... }:

let
  theuser = import ./user.nix { inherit pkgs; };
in
{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  ${theuser.name} = theuser."${theuser.name}";
}
