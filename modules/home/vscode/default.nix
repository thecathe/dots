{
  lib,
  pkgs,
  config,
  ...
}: let
  globalSettings = import ./settings/global;
  globalKeybindings = import ./keybindings.nix;
  vscodeLib = import ./lib.nix {inherit lib globalSettings globalKeybindings;};
  features = builtins.mapAttrs (_: path: import path {inherit pkgs config;}) {
    nix = ./features/nix.nix;
    kdl = ./features/kdl.nix;
    ocaml = ./features/ocaml.nix;
    erlang = ./features/erlang.nix;
    go = ./features/go.nix;
    haskell = ./features/haskell.nix;
    python = ./features/python.nix;
    java = ./features/java.nix;
    sql = ./features/sql.nix;
    web = ./features/web.nix;
    ssh = ./features/ssh.nix;
    git = ./features/git.nix;
    pdf = ./features/pdf.nix;
    json = ./features/json.nix;
    latex = ./features/latex.nix;
    vsrocq = ./features/vsrocq.nix;
    markdown = ./features/markdown.nix;
    forester = ./features/forester.nix;
    languagetool = ./features/languagetool.nix;
    better-comments = ./features/better-comments.nix;
    disable-breakpoint = ./features/disable-breakpoint.nix;
    unicode-math-symbols = ./features/unicode-math-symbols.nix;
    claude = ./features/claude.nix;
    theme = ./features/theme.nix;
    utils = ./features/utils.nix;
  };
  groups = import ./groups.nix {inherit features;};
  defaultProfile = vscodeLib.mkProfile (groups.default);
  # projects
  indimoProfile = vscodeLib.mkProfile (groups.indimo);
  mebiProfile = vscodeLib.mkProfile (groups.mebi);
  cloakamlProfile = vscodeLib.mkProfile (groups.cloakaml);
  webserverProfile = vscodeLib.mkProfile (groups.webserver);
  # languages
  latexProfile = vscodeLib.mkProfile (groups.latex);
  foresterProfile = vscodeLib.mkProfile (groups.forester);
  ocamlProfile = vscodeLib.mkProfile (groups.ocaml);
  rocqProfile = vscodeLib.mkProfile (groups.rocq);
  pythonProfile = vscodeLib.mkProfile (groups.python);
  goProfile = vscodeLib.mkProfile (groups.go);
  haskellProfile = vscodeLib.mkProfile (groups.haskell);
  erlangProfile = vscodeLib.mkProfile (groups.erlang);
  javaProfile = vscodeLib.mkProfile (groups.java);
in {
  programs.vscode = {
    enable = true;
    # Nix never ships setuid-root binaries in the store (only NixOS's
    # security.wrappers provides that; this host is standalone home-manager,
    # not NixOS - same class of issue as hosts/worklaptop/modules/wm/niri.nix's
    # swaylock/unix_chkpwd fix). Electron's chrome-sandbox helper needs to be
    # setuid-root to use the SUID sandbox, so the unwrapped nix-store vscode
    # refuses to launch a GUI window at all ("SUID sandbox helper binary...
    # is not configured correctly"). --no-sandbox skips that requirement.
    package = pkgs.symlinkJoin {
      name = "vscode-no-sandbox";
      paths = [pkgs.vscode];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/code \
          --add-flags "--no-sandbox" \
          --prefix PATH : ${lib.makeBinPath [pkgs.beamPackages.erlang pkgs.beamPackages.rebar3]}
      '';
      # TODO(erlang): the PATH prefix above exists because pgourlain.erlang
      # unconditionally shells out to `rebar3`/`escript` to compile its "Erlang
      # bridge" on activation. As of the extensions-per-profile scoping fix
      # (see lib.nix), it should only be active in the `erlang`/`indimo`/
      # `cloakaml` profiles, but per-profile extension activation is a known
      # upstream weak point (nix-community/home-manager#7880, #8793) so this
      # stays as a safety net. Remove it once that's confirmed reliable and/or
      # fixed upstream.
    };
    # false because profiles beyond `default` are declared below; the module
    # itself only supports mutableExtensionsDir=true when no non-default
    # profiles exist (otherwise it's a no-op with a warning anyway).
    mutableExtensionsDir = false;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    profiles = {
      # must set icons manually in vscode
      default = defaultProfile.profile;
      "indimo" = indimoProfile.profile;
      "mebi" = mebiProfile.profile;
      "cloakaml" = cloakamlProfile.profile;
      "webserver" = webserverProfile.profile;
      "ocaml" = ocamlProfile.profile;
      "rocq" = rocqProfile.profile;
      "latex" = latexProfile.profile;
      "forester" = foresterProfile.profile;
      "python" = pythonProfile.profile;
      "go" = goProfile.profile;
      "haskell" = haskellProfile.profile;
      "erlang" = erlangProfile.profile;
      "java" = javaProfile.profile;
    };
  };
}
