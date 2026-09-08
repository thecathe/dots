{pkgs, ...}: {
  home.packages = [
    pkgs.tectonic
    (pkgs.texliveSmall.withPackages (ps: [ps.chktex]))
  ];
}
