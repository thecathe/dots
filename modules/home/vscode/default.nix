{ lib, pkgs, ... }:
let
  globalExtensions = with pkgs.vscode-extensions; [
    ### essential
    mkhl.direnv
    ### nix
    bbenoist.nix
    kamadorueda.alejandra # fmt
    jnoortheen.nix-ide
    jeff-hykin.better-nix-syntax
    ### md
    yzhang.markdown-all-in-one
    ### useful
    natqe.reload
    christian-kohler.path-intellisense
    wraith13.zoombar-vscode
    ### visuals
    aaron-bond.better-comments
    amos402.scope-bar
    ### theme
    jdinhlife.gruvbox
  ];
in
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    # profiles =
    #   builtins.mapAttrs
    #     (
    #       name: profileConfig:
    #       profileConfig
    #       // {
    #         extensions = globalExtensions ++ (profileConfig.extensions or [ ]);
    #       }
    #     )
    #     {
    #       "nix" = {
    #         extensions = with pkgs.vscode-extensions; [
    #           bbenoist.nix
    #           kamadorueda.alejandra # fmt
    #           jnoortheen.nix-ide
    #           jeff-hykin.better-nix-syntax
    #         ];
    #       };

    #       "ocaml" = {

    #       };
    #       "erlang" = {

    #       };
    #       "go" = {

    #       };
    #       "python" = {

    #       };
    #       "web" = {

    #       };

    #     };
  };
}
