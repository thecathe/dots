{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [ ]
    ++ (with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [
      erlang-language-platform.erlang-language-platform
      erlang-ls.erlang-ls
      pgourlain.erlang
    ]);
  settings = {
    "[erlang]" = {
      # "editor.defaultFormatter" = "erlfmt";
      "editor.defaultFormatter" = "erlang-language-platform.erlang-language-platform";
    };
    "erlang.codeLensEnabled" = true;
    "elp" = {
      "hoverActions.enable" = true;
      "typesOnHover.enable" = true;
      "diagnostics.enableOtp" = true;
      "edoc.enable" = true;
      "lens.links.enable" = true;
    };
    "files.exclude" = {
      "**/*.beam" = true;
    };
  };
}
