{ lib, ... }: {
  programs.obsidian = {
    enable = true;

  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "obsidian"
    ];
}
