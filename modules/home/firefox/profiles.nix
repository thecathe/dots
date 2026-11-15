# Takes the main profile's name (dots.firefox.profile).
profile: {
  # https://mynixos.com/home-manager/options/programs.firefox.profiles.%3Cname%3E
  ${profile} = {
    id = 0;
    name = profile;
    isDefault = true;
    settings = {
      # "extensions.autoDisableScopes" = 0;
      #
      # Orange clock badge on URL-bar history rows (looked into 2026-11-15, left as is on purpose):
      # not an error. Firefox's "Nova" UI (browser.nova.enabled, on by default in 159.0.1) badges
      # each history result and fills the badge with the system accent colour, which DMS sets in
      # dconf (org.gnome.desktop.interface accent-color). To change it: set
      # "browser.nova.enabled" = false here, or add a userChrome rule for .urlbarView-type-icon
      # (needs "toolkit.legacyUserProfileCustomizations.stylesheets" = true).
      # Details: devlog dots/firefox-nova-badge.md.
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
