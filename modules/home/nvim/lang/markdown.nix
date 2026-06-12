{
  pkgs,
  lib,
  ...
}: {
  xdg.configFile."nvim/lua/lang/markdown.lua".source = ./markdown.lua;
  programs.neovim = {
    extraPackages = with pkgs; [marksman prettier];
    initLua = lib.mkAfter "require('lang.markdown')";
  };
}
