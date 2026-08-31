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
          "options" = {
            "nixos" = {
              "expr" = "(builtins.getFlake \"/home/cathe/dots\").nixosConfigurations.nixos.options";
            };
            "home_manager" = {
              "expr" = "(builtins.getFlake \"/home/cathe/dots\").nixosConfigurations.nixos.options.home-manager.users.cathe";
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
