{ pkgs, lib, ... }:

{
  imports = [
    ./languages/ocaml.nix
    ./languages/erlang.nix
    ./languages/go.nix
    ./languages/markdown.nix
    # ./languages/latex.nix
  ];
}
