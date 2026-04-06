{ ... }:
{
  # https://mynixos.com/options/programs.firefox
  # https://wiki.nixos.org/wiki/Firefox
  programs.firefox = {
    enable = true;
    policies = {
      DisabelTelemetry = true;
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true;
      # ExtensionSettings =
      #   let
      #     moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
      #   in
      #   {
      #     # For blocking all extensions (except those specified later)
      #     # "*".installation_mode = "blocked";

      #     "uBlock0@raymondhill.net" = {
      #       install_url = moz "ublock-origin";
      #       installation_mode = "force_installed";
      #       updates_disabled = true;
      #     };
      #   };
    };
    preferences = {
      # see pdf options: https://github.com/mozilla/pdf.js/blob/master/extensions/chromium/options/options.html
      "pdfjs.defaultZoomValue" = "auto";
      "pdfjs.sidebarViewOnLoad" = 0; # None
      "pdfjs.cursorToolOnLoad" = 1; # Hand tool
      "pdfjs.textLayerMode" = 1; # Enable text selection
      "pdfjs.externalLinkTarget" = 2; # New tab
      "pdfjs.scrollModeOnLoad" = 2; # Wrapped scrolling
      "pdfjs.spreadModeOnLoad" = 0; # No spreads
    };
  };
}
