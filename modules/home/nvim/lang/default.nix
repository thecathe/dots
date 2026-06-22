{lib, ...}: {
  imports = [
    ./nix.nix
    ./ocaml.nix
    ./dune.nix
    ./erlang.nix
    ./go.nix
    ./markdown.nix
    # ./languages/latex.nix
  ];

  programs.neovim.initLua = lib.mkAfter "require('conform').formatters_by_ft.lua = { 'stylua' }";
}
