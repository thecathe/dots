{ pkgs, ... }:
let
  # ltex-plus downloads its own ltex-ls-plus server (including a bundled JDK)
  # into its own extension directory on first activation -- but under
  # home-manager that directory is a read-only Nix store symlink, so the
  # download's mkdtemp() call fails with EROFS and grammar checking never
  # starts. Fetch the same release Nix-declaratively instead and point
  # ltex.ltex-ls.path at it directly, skipping that runtime download
  # entirely. The bundled JDK inside the release tarball is a generic-Linux
  # build that isn't patched for NixOS's non-FHS dynamic linker, so it's left
  # out of $out below; ltex.java.path instead points at a proper nixpkgs JDK,
  # which the launcher script (bin/ltex-ls-plus) already prefers over its own
  # bundled one whenever JAVA_HOME is set non-empty (which the extension does
  # whenever ltex.java.path is set, from ltex.java.path straight to the
  # JAVA_HOME env var of the spawned process).
  #
  # Version/hash must stay in lockstep with the installed ltex-plus.vscode-ltex-plus
  # version above -- its DependencyManager class hardcodes both the expected
  # ltex-ls-plus release tag and this exact hash per platform tarball; bump
  # both together when upgrading (grep dist/extension.js in the built
  # extension for "_toBeDownloadedLtexLsHashDigests" to find the new ones).
  ltexLsPlus = pkgs.stdenv.mkDerivation {
    pname = "ltex-ls-plus";
    version = "18.7.0";
    src = pkgs.fetchurl {
      url = "https://github.com/ltex-plus/ltex-ls-plus/releases/download/18.7.0/ltex-ls-plus-18.7.0-linux-x64.tar.gz";
      sha256 = "1e16df6c578dc76ff97d644445d126ba6fba5c2e8e174178ab86372652fd7612";
    };
    sourceRoot = "ltex-ls-plus-18.7.0";
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r bin lib changelog.xml README.md LICENSE.md ACKNOWLEDGMENTS.md "$out/"
      runHook postInstall
    '';
  };
in
{
  # ltex-plus.vscode-ltex-plus is the actively-maintained fork of the now-archived
  # valentjn.vscode-ltex. forester's forest-keeper extension hardcodes a check for
  # the old extension ID to find-and-force-activate LTeX (see the overrideAttrs
  # patch on forest-keeper in modules/home/vscode/features/forester.nix, which
  # retargets that check at this extension's ID instead).
  extensions = [ pkgs.vscode-extensions.ltex-plus.vscode-ltex-plus ];
  settings = {
    "ltex.ltex-ls.path" = "${ltexLsPlus}";
    "ltex.java.path" = "${pkgs.jdk21_headless}";
    "ltex.enabled" = [
      "bibtex"
      "context"
      "context.tex"
      "html"
      "latex"
      "markdown"
      "mdx"
      "typst"
      "asciidoc"
      "neorg"
      "org"
      "quarto"
      "restructuredtext"
      "rsweave"
      "forester"
    ];

    # "ltex" = {
    #                   "disabledRules" = {
    #                     "en-GB" = [ "SENTENCE_WHITESPACE" ];
    #                   };
    #                   "enabledRules" = { };
    #                   "additionalRules.motherTongue" = "en-GB";
    #                   "language" = "en-GB";
    #                   "completionEnabled" = true;
    #                 };
  };
}
