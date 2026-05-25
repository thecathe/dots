{ pkgs, ... }:

{
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  cathe = {
    id = 0;
    name = "cathe";
    isDefault = true;
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
