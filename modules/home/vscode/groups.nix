{features}: let
  defaultGroup = with features; [
    nix
    git
    markdown
    better-comments
    json
    kdl
    theme
    utils
    claude
  ];
in let
  latexGroup = with features;
    [
      latex
      languagetool
      disable-breakpoint
    ]
    ++ defaultGroup;
  ocamlGroup = with features;
    [
      ocaml
      disable-breakpoint
      unicode-math-symbols
    ]
    ++ defaultGroup;
  rocqGroup = with features;
    [
      vsrocq
      disable-breakpoint
      unicode-math-symbols
    ]
    ++ defaultGroup ++ ocamlGroup;
  foresterGroup = with features;
    [
      forester
      languagetool
      disable-breakpoint
      unicode-math-symbols
    ]
    ++ defaultGroup;
  pythonGroup = [features.python] ++ defaultGroup;
  goGroup = with features;
    [
      go
      disable-breakpoint
    ]
    ++ defaultGroup;
  erlangGroup = with features;
    [
      erlang
      disable-breakpoint
    ]
    ++ defaultGroup;
  javaGroup = [features.java] ++ defaultGroup;
in {
  # latex merged in here (rather than into the defaultGroup binding above,
  # which every other group also extends) until upstream fixes per-profile
  # extension enablement and the dedicated `latex` profile actually works
  default = defaultGroup ++ [features.latex];
  latex = latexGroup;
  ocaml = ocamlGroup;
  rocq = rocqGroup;
  forester = foresterGroup;
  python = pythonGroup;
  go = goGroup;
  erlang = erlangGroup;
  java = javaGroup;
  indimo = with features;
    [
      web
      sql
      disable-breakpoint
    ]
    ++ defaultGroup
    ++ erlangGroup
    ++ goGroup
    ++ pythonGroup;
  mebi = defaultGroup ++ rocqGroup;
  cloakaml = defaultGroup ++ ocamlGroup ++ erlangGroup;
  webserver = with features;
    [
      web
      sql
      ssh
      disable-breakpoint
    ]
    ++ defaultGroup;
}
