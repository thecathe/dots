{
  config,
  lib,
  pkgs,
  ...
}: {
  options.dots.latex.enable = lib.mkEnableOption "the LaTeX tools (tectonic and a small texlive)" // {default = true;};

  config = lib.mkIf config.dots.latex.enable {
    home.packages = [
      pkgs.tectonic
      (pkgs.texliveSmall.withPackages (ps: [ps.chktex]))
    ];
  };
}
