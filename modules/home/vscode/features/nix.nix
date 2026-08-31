{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    bbenoist.nix
    b4dm4n.vscode-nixpkgs-fmt
    kamadorueda.alejandra
    jnoortheen.nix-ide
    jeff-hykin.better-nix-syntax
  ];
  settings = {
    "nix" = {
      "enableLanguageServer" = true;
      "serverPath" = "nixd";
      "serverSettings" = {
        "nixd" = {
          "nixpkgs" = {
            "expr" = "import <nixpkgs> {}";
          };
          "formatting" = {
            "command" = [
              "alejandra"
            ];
          };
          # builtins.getFlake fails on the ~/dots symlink ("path is a symlink")
          # so these use the real repo path instead.
          "options" = {
            "nixos" = {
              "expr" = "(builtins.getFlake \"/home/cathe/Documents/git/thecathe/dots\").nixosConfigurations.nixos.options";
            };
            "home_manager" = {
              "expr" = "(builtins.getFlake \"/home/cathe/Documents/git/thecathe/dots\").nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions []";
            };
          };
        };
      };
    };
    "workbench.settings.applyToAllProfiles" = [
      "nix.enableLanguageServer"
      "nix.serverPath"
      "nix.serverSettings"
    ];
  };
}
