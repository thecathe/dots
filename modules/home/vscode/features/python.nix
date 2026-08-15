{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [
      ms-python.python
      ms-python.vscode-python-envs
    ]
    ++ [
      # pkgs.nix-vscode-extensions.kevinrose.vsc-python-indent
    ];
  settings = {
    "[python]" = {
      # "editor.defaultFormatter" = "KevinRose.vsc-python-indent";
    };
  };
}
