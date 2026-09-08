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
  ];
in let
  latexGroup = with features;
    [
      latex
      disable-breakpoint
    ]
    ++ defaultGroup;
  ocamlGroup = with features;
    [
      ocaml
      disable-breakpoint
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
  python = pythonGroup;
  go = goGroup;
  erlang = erlangGroup;
  java = javaGroup;
  indimo = with features;
    [
      web
      sql
      claude
      disable-breakpoint
    ]
    ++ defaultGroup
    ++ erlangGroup
    ++ goGroup
    ++ pythonGroup;
  mebi = with features;
    [
      vsrocq
      disable-breakpoint
    ]
    ++ defaultGroup
    ++ ocamlGroup;
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
