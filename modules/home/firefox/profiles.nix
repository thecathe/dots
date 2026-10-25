# Takes the main profile's name (dots.firefox.profile).
profile: {
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  ${profile} = {
    id = 0;
    name = profile;
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
  priv = {
    id = 1;
    name = "priv";
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
