{ pkgs, ... }:
{
  extensions =
    with pkgs.vscode-extensions;
    [ jdinhlife.gruvbox ]
    ++ (with pkgs.nix-vscode-extensions.vscode-marketplace-release-universal; [
      yile-ou.paddy-color-theme
    ]);
  settings = {
    "workbench" = {
      # "colorTheme" = "Gruvbox Dark Soft";
      "colorTheme" = "paddy-eucalyptus-upright";
      "settings.applyToAllProfiles" = [ "workbench.colorTheme" ];
    };
  };
}
