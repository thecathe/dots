{ pkgs, ... }:

let
  thenixuser = import "/home/cathe/dots/user.nix" { };
  name = thenixuser.name;
in
{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  programs.firefox.profiles."${name}" = {
    id = 0;
    name = name;
    isDefault = true;
    settings = {
      "extensions.autoDisableScopes" = 0;
    };
    extensions = {
      packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
      ];
    };
  };
}
