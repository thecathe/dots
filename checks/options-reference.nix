# The generated `dots.*` options reference (lib/options-doc.nix) is complete, honest
# and publishable. Three things, each of which fails with a message saying what to do:
#
#  - Complete: building the reference fails on an option without a description
#    (nixosOptionsDoc's own `warningsAreErrors`), so building it at all is the check.
#  - Honest: only `dots.*` options appear, and no default or example carries a value
#    that came from the evaluation the reference was made from (the placeholder user
#    `consumer`, a store path). Such a default means the option needs a `defaultText`;
#    without one the page would show one machine's value as if it were everyone's.
#  - Publishable: the two pages the GitHub Action publishes
#    (.github/workflows/options-reference.yml) exist and are not empty, so a change that
#    broke them fails here, before a merge, and not in the Action after a push.
{
  inputs,
  optionsDoc,
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in {
  options-reference =
    pkgs.runCommand "options-reference" {
      nativeBuildInputs = [pkgs.jq];
    } ''
      ref=${optionsDoc.reference}
      failed=0

      for set in home nixos; do
        json=$ref/options-$set.json

        outside=$(jq -r 'keys[] | select(startswith("dots.") | not)' "$json")
        if [ -n "$outside" ]; then
          echo "options-reference: $set documents options outside dots.*:" >&2
          echo "$outside" >&2
          failed=1
        fi

        # `default` and `example` are {_type = "literalExpression"; text} or a plain value.
        leaked=$(jq -r '
          def text: if type == "object" and has("text") then .text else tostring end;
          to_entries[]
          | select(
              ((.value.default // "") | text | test("consumer|/nix/store"))
              or ((.value.example // "") | text | test("/nix/store"))
            )
          | .key' "$json")
        if [ -n "$leaked" ]; then
          echo "options-reference: the $set page shows a value from the evaluation (the" >&2
          echo "placeholder user or a store path) in the default or example of:" >&2
          echo "$leaked" >&2
          echo "Give each a defaultText (lib.literalExpression \"...\") that says how it is computed." >&2
          failed=1
        fi
      done

      for page in options-home.md options-nixos.md; do
        if ! [ -s "$ref/$page" ]; then
          echo "options-reference: $page is missing or empty, so the Action would publish nothing for it" >&2
          failed=1
        fi
      done

      [ "$failed" = 0 ] || exit 1
      touch $out
    '';
}
