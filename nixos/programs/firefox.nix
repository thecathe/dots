{ ... }:
{
  # https://mynixos.com/options/programs.firefox
  programs.firefox = {
    enable = true;
    policies = {
      DisabelTelemetry = true;
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
