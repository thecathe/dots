{pkgs, ...}: {
  extensions = with pkgs.vscode-extensions; [
    tamasfe.even-better-toml
  ];
  settings = {
  };
}
