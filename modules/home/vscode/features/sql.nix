{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    yy0931.vscode-sqlite3-editor
  ];
  settings = {

  };
}
