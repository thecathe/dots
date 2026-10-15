{config, ...}: let
  home = config.home.homeDirectory;
in {
  # DankSearch (dsearch): indexed filesystem search behind DMS Spotlight's
  # Files tab and `/` prefix (see dankLauncherV2Include*InAll in
  # settings.json for merging results into the All tab). The module comes from
  # the danksearch flake input (homeModules.default, wired in flake.nix) and
  # runs `dsearch serve` as a user service.
  #
  # Deliberately scoped rather than indexing all of $HOME: dsearch watches
  # every indexed directory with inotify, and the per-user limit
  # (fs.inotify.max_user_watches, 65536 on the Ubuntu host) is already well
  # over half used by editors etc. ~/Documents/git alone is ~23k directories,
  # so it is excluded here - repos are covered live, with no index or
  # watches, by the fdSearch launcher plugin (see dms.nix) instead.
  #
  # `config` is written verbatim to ~/.config/danksearch/config.toml. The
  # docs don't state the default index paths, so they are always spelled out.
  # exclude_dirs replaces dsearch's built-in noise list unless
  # merge_default_exclude_dirs is set, hence it on every entry.
  programs.dsearch = {
    enable = true;
    config = {
      index_paths = [
        {
          path = "${home}/Documents";
          max_depth = 8;
          exclude_hidden = true;
          extract_exif = false;
          exclude_dirs = ["git"];
          merge_default_exclude_dirs = true;
        }
        {
          path = "${home}/Downloads";
          max_depth = 4;
          exclude_hidden = true;
          extract_exif = false;
          merge_default_exclude_dirs = true;
        }
        {
          path = "${home}/Pictures";
          max_depth = 6;
          exclude_hidden = true;
          extract_exif = true;
          merge_default_exclude_dirs = true;
        }
        {
          path = "${home}/Videos";
          max_depth = 6;
          exclude_hidden = true;
          extract_exif = false;
          merge_default_exclude_dirs = true;
        }
      ];
    };
  };
}
