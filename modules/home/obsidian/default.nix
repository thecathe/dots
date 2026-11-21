{
  config,
  lib,
  ...
}: {
  options.dots.obsidian.enable = lib.mkEnableOption "Obsidian" // {default = true;};

  config = lib.mkIf config.dots.obsidian.enable {
    programs.obsidian = {
      enable = true;
    };
  };
}
