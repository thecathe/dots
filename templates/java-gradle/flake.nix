{
  description = "Java project with Gradle";

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
          # Gradle is overridden to run on the same JDK the shell exposes, so
          # `gradle` and `javac` never disagree about the Java version.
          packages = with pkgs; [
            jdk
            (gradle.override { java = jdk; })
            jdt-language-server
          ];
        };
      });
    };
}
