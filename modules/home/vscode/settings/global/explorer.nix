{
  # Controls when the folding controls on the gutter are shown.
  #  - always: Always show the folding controls.
  #  - never: Never show the folding controls and reduce the gutter size.
  #  - mouseover: Only show the folding controls when the mouse is over the gutter.
  "editor.showFoldingControls" = "always";

  # Controls the strategy for computing folding ranges.
  #  - auto: Use a language-specific folding strategy if available, else the
  #    indentation-based one.
  #  - indentation: Use the indentation-based folding strategy.
  "editor.foldingStrategy" = "indentation";

  # Zoom the font of the editor when using mouse wheel and holding `Ctrl`.
  "editor.mouseWheelZoom" = true;

  # Controls how suggestions are pre-selected when showing the suggest list.
  #  - first: Always select the first suggestion.
  #  - recentlyUsed: Select recent suggestions unless further typing selects one.
  #  - recentlyUsedByPrefix: Select suggestions based on previous prefixes.
  "editor.suggestSelection" = "first";

  # Format a file on save. A formatter must be available and the editor must
  # not be shutting down. When `files.autoSave` is set to `afterDelay`, the
  # file will only be formatted when saved explicitly.
  "editor.formatOnSave" = true;

  # Controls whether the editor should automatically format the pasted
  # content. A formatter must be available and the formatter should be able
  # to format a range in a document.
  "editor.formatOnPaste" = true;

  # Controls the wrapping column of the editor when `editor.wordWrap` is
  # `wordWrapColumn` or `bounded`.
  "editor.wordWrapColumn" = 72;

  # The number of spaces a tab is equal to. This setting is overridden based
  # on the file contents when `editor.detectIndentation` is on.
  "editor.tabSize" = 2;

  # Controls whether `editor.tabSize` and `editor.insertSpaces` will be
  # automatically detected when a file is opened based on the file contents.
  "editor.detectIndentation" = false;

  # Controls the font size in pixels.
  # "editor.fontSize" = 16.0;

  # Controls the font family.
  "editor.fontFamily" = "JetBrainsMono Nerd Font Mono";

  # Controls font family of inlay hints in the editor. When set to empty, the
  # `editor.fontFamily` is used.
  "editor.inlayHints.fontFamily" = "JetBrainsMono Nerd Font Mono";

  # Controls the font family of the inline suggestions.
  "editor.inlineSuggest.fontFamily" = "JetBrainsMono Nerd Font Mono";

  # Controls whether each bracket type has its own independent color pool.
  "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;

  # Controls whether bracket pair guides are enabled or not.
  #  - true: Enables bracket pair guides.
  #  - active: Enables bracket pair guides only for the active bracket pair.
  #  - false: Disables bracket pair guides.
  "editor.guides.bracketPairs" = true;

  # Controls when the minimap slider is shown.
  "editor.minimap.showSlider" = "always";

  # Controls the font size of section headers in the minimap.
  "editor.minimap.sectionHeaderFontSize" = 10.285714285714286;

  # Run Code Actions for the editor on save. Code Actions must be specified
  # and the editor must not be shutting down. When `files.autoSave` is set to
  # `afterDelay`, Code Actions will only be run when the file is saved
  # explicitly. Example: `"source.organizeImports": "explicit"`
  "editor.codeActionsOnSave" = {
    "source.fixAll" = "explicit";
    "source.organizeImports" = "never";
  };

  # Controls whether the minimap is hidden automatically.
  #  - none: The minimap is always shown.
  #  - mouseover: The minimap is hidden when mouse is not over the minimap and shown when mouse is over the minimap.
  #  - scroll: The minimap is only shown when the editor is scrolled
  "editor.minimap.autohide" = "none";

  # Controls whether the minimap is shown.
  "editor.minimap.enabled" = true;

  # Limit the width of the minimap to render at most a certain number of columns.
  "editor.minimap.maxColumn" = 120;

  # Render the actual characters on a line as opposed to color blocks.
  "editor.minimap.renderCharacters" = true;

  # Scale of content drawn in the minimap: 1, 2 or 3.
  "editor.minimap.scale" = 1;

  # Controls the side where to render the minimap.
  "editor.minimap.side" = "right";

  # Controls the size of the minimap.
  #  - proportional: The minimap has the same size as the editor contents (and might scroll).
  #  - fill: The minimap will stretch or shrink as necessary to fill the height of the editor (no scrolling).
  #  - fit: The minimap will shrink as necessary to never be larger than the editor (no scrolling).
  "editor.minimap.size" = "proportional";
}
