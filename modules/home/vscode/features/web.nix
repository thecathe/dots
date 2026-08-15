{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    matthewpi.caddyfile-support
    ecmel.vscode-html-css
  ];
  settings = {

  };
}
