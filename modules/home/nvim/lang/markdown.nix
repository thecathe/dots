{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.dots.nvim.enable {
    xdg.configFile."nvim/lua/lang/markdown.lua".source = ./markdown.lua;
    programs.neovim = {
      extraPackages = with pkgs; [marksman prettier];
      initLua = lib.mkAfter "require('lang.markdown')";
    };
  };
}
