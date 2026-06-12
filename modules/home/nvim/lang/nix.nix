{ lib, ... }:
{
  xdg.configFile."nvim/lua/lang/nix.lua".source = ./nix.lua;
  programs.neovim.initLua = lib.mkAfter "require('lang.nix')";
}
