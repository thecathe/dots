{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [ redhat.java ];
  settings = {

  };
}
