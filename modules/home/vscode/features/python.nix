{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [
      ms-python.python
      ms-python.vscode-python-envs
      # Language server. ms-python.python has none of its own: it launches
      # Pylance (unfree, and licensed for Microsoft's VS Code builds only)
      # if present, else falls back to Jedi -- but the nixpkgs build of
      # ms-python.python omits python_files/lib/jedilsp, so that fallback
      # dies with "No module named 'jedi_language_server'". basedpyright is
      # free, bundles its own server, and uses the interpreter from the
      # environment direnv provides.
      detachhead.basedpyright
    ]
    ++ [
      # pkgs.nix-vscode-extensions.kevinrose.vsc-python-indent
    ];
  settings = {
    # Stop ms-python.python starting its (broken, see above) Jedi fallback;
    # basedpyright supplies completion, hover and diagnostics instead.
    "python.languageServer" = "None";
    "[python]" = {
      # "editor.defaultFormatter" = "KevinRose.vsc-python-indent";
    };
  };
}
