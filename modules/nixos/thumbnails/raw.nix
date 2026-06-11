{ pkgs, ... }:

## https://wiki.nixos.org/wiki/Thumbnails#Enable_RAW_(Camera)_Image_Thumbnails
{
  environment.systemPackages = with pkgs; [
    gdk-pixbuf
    # Allow gdk-pixbuf to thumbnail RAW photos by extracting the embedded jpeg
    (writeTextFile {
      name = "raw-embedded-jpeg-thumbnailer";
      destination = "/share/thumbnailers/raw-embedded-jpeg.thumbnailer";
      text = ''
        [Thumbnailer Entry]
        TryExec=gdk-pixbuf-thumbnailer
        Exec=gdk-pixbuf-thumbnailer -s %s %u %o
        MimeType=image/x-canon-crw;image/x-canon-cr2;image/x-canon-cr3;image/x-adobe-dng;image/x-dng;
      '';
    })
    # Other MimeTypes that include embedded jpeg may work as well (e.g. Nikon .nef, Sony .arf, etc)
    # Test other formats by adding them above
  ];
}
