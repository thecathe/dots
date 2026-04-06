{ ... }:

let
  name = "default";
in
{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  programs.firefox.profiles."${name}" = {
    id = 0;
    name = name;
    isDefault = true;
  };
}
