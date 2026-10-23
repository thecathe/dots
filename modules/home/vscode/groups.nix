{features}: let
  defaultGroup = with features; [
    nix
    git
    markdown
    better-comments
    tab-groups
    json
    toml
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
  # spellcheck rather than languagetool: LTeX's JVM costs ~1 GB and
  # forest-keeper force-starts it on opening any .tree, even though LTeX has
  # no forester parser and so only sees the trees as plain text.
  foresterGroup = with features;
    [
      forester
      spellcheck
      disable-breakpoint
      unicode-math-symbols
      pdf
    ]
    ++ defaultGroup;
  pythonGroup = [features.python] ++ defaultGroup;
  goGroup = with features;
    [
      go
      disable-breakpoint
    ]
    ++ defaultGroup;
  haskellGroup = with features;
    [
      haskell
      disable-breakpoint
      unicode-math-symbols
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
  haskell = haskellGroup;
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
