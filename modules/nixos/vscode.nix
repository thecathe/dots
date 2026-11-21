{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.vscode.enable = lib.mkEnableOption "stock VS Code, system-wide" // {default = true;};

  config = lib.mkIf config.dots.vscode.enable {
    environment.systemPackages = with pkgs; [
      vscode
    ];
  };
}
