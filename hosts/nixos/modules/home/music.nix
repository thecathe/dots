{...}: {
  # Host-specific: musicDirectory only exists on this machine's drive.
  services.mpd = {
    enable = true;
    musicDirectory = "/mnt/data/Multimedia/Music";
    # dataDir/dbFile default to ~/.local/share/mpd - kept off the NTFS drive.
  };

  # MPD -> MPRIS2 D-Bus bridge, so DMS/playerctl see MPD (and rmpc) like any other player.
  services.mpdris2-rs.enable = true;
}
