{ pkgs, config, ... }:
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
          # builtins.getFlake fails on the ~/dots symlink ("path is a symlink"),
          # so this uses the real repo path instead. Interpolated from
          # config.home.homeDirectory since this module is shared across
          # hosts with different usernames (cathe on nixos, jjp38 here).
          "options" = {
            "nixos" = {
              "expr" = "(builtins.getFlake \"${config.home.homeDirectory}/Documents/git/thecathe/dots\").nixosConfigurations.nixos.options";
            };
            "home_manager" = {
              "expr" = "(builtins.getFlake \"${config.home.homeDirectory}/Documents/git/thecathe/dots\").homeConfigurations.\"cathe@worklaptop\".options";
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
