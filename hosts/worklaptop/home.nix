{ config, pkgs, inputs, ... }:
let nixgl = inputs.nixgl; in
 {
  imports = [
    ../../modules/home
  ];

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  home.username = "jjp38";
  home.homeDirectory = "/home/jjp38";
  home.stateVersion = "25.11";
  
  home.sessionPath = [ "$HOME/dots/bin" ];

  # Required for standalone home-manager (non-NixOS hosts)
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    wget fzf git gh tmux
    nix nixfmt
  ];

  ## override 
  programs.kitty = {enable=true;
package = (pkgs.writeShellScriptBin "kitty" ''
    exec ${nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel}/bin/nixGlIntel ${pkgs.kitty}/bin/kitty "$@"
  '');
  };

  xdg.desktopEntries.kitty = {
        name = "Kitty";
    genericName = "Terminal Emulator";
    exec = "${nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel}/bin/nixGLIntel ${pkgs.kitty}/bin/kitty";
    icon = "kitty";
    terminal = false;
    categories = [ "System" "TerminalEmulator" ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
