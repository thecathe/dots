{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    rocq-prover.vsrocq
  ];
  settings = {

  };
}
