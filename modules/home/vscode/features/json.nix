{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    zainchen.json
  ];
  settings = {

  };
}
