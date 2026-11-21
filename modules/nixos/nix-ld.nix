{
  config,
  lib,
  ...
}: {
  options.dots.nixLd.enable = lib.mkEnableOption "nix-ld, so prebuilt Linux binaries run unmodified" // {default = true;};

  config = lib.mkIf config.dots.nixLd.enable {
    # Lets prebuilt, non-Nix-patched Linux binaries run unmodified by providing
    # the generic dynamic linker (/lib64/ld-linux-x86-64.so.2) they hardcode,
    # which doesn't exist on NixOS otherwise. Needed for e.g. VS Code
    # extensions that bundle their own prebuilt binaries instead of relying on
    # a project-provided toolchain (e.g. erlang-language-platform's `elp` and
    # `eqwalizer`, which otherwise fail with "exec format error").
    programs.nix-ld.enable = true;
  };
}
