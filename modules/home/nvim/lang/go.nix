{ lib, ... }:
{
  xdg.configFile."nvim/lua/lang/go.lua".source = ./go.lua;
  programs.neovim.initLua = lib.mkAfter "require('lang.go')";
}
