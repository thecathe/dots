{ lib, ... }:
{
  xdg.configFile."nvim/lua/lang/erlang.lua".source = ./erlang.lua;
  programs.neovim.initLua = lib.mkAfter "require('lang.erlang')";
}
