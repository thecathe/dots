{
  config,
  lib,
  ...
}: {
  options.dots.zathura.enable = lib.mkEnableOption "the zathura PDF reader" // {default = true;};

  config = lib.mkIf config.dots.zathura.enable {
    ## pdf reader
    programs.zathura = {
      enable = true;
      options = {
        selection-clipboard = "clipboard"; # copy to system clipboard
        recolor = false; # dark mode
      };
    };
  };
}
