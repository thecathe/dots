{
  config,
  lib,
  ...
}: {
  options.dots.navi.enable = lib.mkEnableOption "navi and its cheat sheets" // {default = true;};

  config = lib.mkIf config.dots.navi.enable {
    programs.navi = {
      enable = true;
      enableZshIntegration = true; # Ctrl+G
    };

    # Every .cheat file under ./cheats, grouped by the tags on its `%` lines. It sits in a subfolder
    # of navi's own cheats folder rather than replacing it, so `navi repo add` and cheats written
    # by hand still work.
    xdg.dataFile."navi/cheats/dots".source = ./cheats;
  };
}
