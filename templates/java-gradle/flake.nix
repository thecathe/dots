{
  description = "Java project with Gradle";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
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
  in {
    devShells = forAllSystems (pkgs: let
      # Gradle is overridden to run on the same JDK the shell exposes, so
      # `gradle` and `javac` never disagree about the Java version.
      gradle = pkgs.gradle.override {java = pkgs.jdk;};
    in {
      default = pkgs.mkShell {
        packages = [
          pkgs.jdk
          gradle
          pkgs.jdt-language-server
        ];

        # There is no Gradle wrapper in this template, and redhat.java
        # (the editor's Java extension) only uses a local Gradle when
        # GRADLE_HOME points at one -- otherwise it downloads its own
        # distribution, which needs network and ignores the Gradle above.
        # nixpkgs keeps the real distribution under libexec/gradle.
        GRADLE_HOME = "${gradle}/libexec/gradle";
      };
    });
  };
}
