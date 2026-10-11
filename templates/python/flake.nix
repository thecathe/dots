{
  description = "Python project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      # aarch64-darwin is offered on the assumption nothing here is
      # Linux-specific; it is untested. x86_64-darwin is deliberately absent:
      # nixpkgs dropped support for it, and listing it makes
      # `nix flake check --all-systems` fail outright.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Nix provides the interpreter and tooling. Python packages
          # themselves are managed by uv (pyproject.toml / uv.lock) in a
          # local .venv.
          packages = with pkgs; [
            python3
            uv
            ruff
          ];

          # Make uv use the interpreter above rather than downloading its own
          # (uv's downloaded builds are dynamically linked against paths that
          # don't exist on NixOS).
          UV_PYTHON = pkgs.python3.interpreter;
          UV_PYTHON_DOWNLOADS = "never";

          # Prebuilt wheels (numpy, etc.) may fail on NixOS with a missing
          # libstdc++/libz. If so, uncomment this to expose them.
          # LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          #   pkgs.stdenv.cc.cc.lib
          #   pkgs.zlib
          # ];
        };
      });
    };
}
