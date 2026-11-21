{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.nautilus.enable = lib.mkEnableOption "the Nautilus file manager and gvfs" // {default = true;};

  config = lib.mkIf config.dots.nautilus.enable {
    environment.systemPackages = with pkgs; [
      nautilus
    ];
    services.gvfs.enable = true;
    # services.udisks2.enable = true;
  };
}
