{ ... }:

let
  name = "priv";
in
{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  name = name;
  "${name}" = {
    id = 1;
    name = name;
    isDefault = false;
    settings = {
      # "extensions.autoDisableScopes" = 0;
    };
    # extensions = {
    #   packages = with pkgs.nur.repos.rycee.firefox-addons; [
    #     ublock-origin
    #   ];
    # };
  };
}
