{
  description = "OCaml project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        # Nix provides opam and the system libraries that opam packages
        # compile against. OCaml packages themselves are managed by opam.
        #
        # If an opam package fails to build citing a missing system library,
        # add it here. Common ones are listed below — uncomment as needed.
        buildInputs = with pkgs; [
          opam
          pkg-config
          # openssl
          # gmp
          # zlib
          # libffi
        ];
      };
    };
}
