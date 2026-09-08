{ lib, config, ... }:
{
  xdg.configFile."nvim/lua/lang/nix.lua".text = builtins.replaceStrings
    [ "@@DOTS_PATH@@" ]
    [ "${config.home.homeDirectory}/Documents/git/thecathe/dots" ]
    (builtins.readFile ./nix.lua);
  programs.neovim.initLua = lib.mkAfter "require('lang.nix')";
}
