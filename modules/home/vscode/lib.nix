{
  lib,
  globalSettings ? { },
  globalKeybindings ? [ ],
}:
{
  mkProfile =
    features:
    let
      # append feature specifc keybinds to end, then gently check for exact duplicate bindings
      keybindings = globalKeybindings ++ lib.concatMap (f: f.keybindings or [ ]) features;
      byChord = lib.groupBy (kb: "${kb.key}|${kb.when or ""}") keybindings;
      dupes = lib.filterAttrs (_: v: lib.length v > 1) byChord;
    in
    assert lib.assertMsg (
      dupes == { }
    ) "duplicate vscode keybindings: ${toString (lib.attrNames dupes)}";
    {
      # move into profile once extension issue fixed
      extensions = lib.concatMap (f: f.extensions) features;
      profile = {
        userSettings = lib.foldl' (
          acc: f: lib.recursiveUpdate acc (f.settings or { })
        ) globalSettings features;
        inherit keybindings;
      };
    };
}
