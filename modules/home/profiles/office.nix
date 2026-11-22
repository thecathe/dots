# The home `office` profile: applications for documents, spreadsheets and slides.
# Today that is LibreOffice; other document tools can join it.
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.profile.office.enable = lib.mkEnableOption "the home office profile: LibreOffice";

  config = lib.mkIf config.dots.profile.office.enable {
    home.packages = [pkgs.libreoffice];
  };
}
