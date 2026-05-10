{ pkgs, ... }:

let
  theuser = import ./user.nix { inherit pkgs; };
  thepriv = import ./priv.nix { };
in
{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  ${theuser.name} = theuser."${theuser.name}";
  ${thepriv.name} = thepriv."${thepriv.name}";
}
