{
  # Disable floating windows
  "workbench.editor.useModal" = "off";

  # Controls if the empty editor text hint should be visible in the editor.
  "workbench.editor.empty.hint" = "hidden";

  # Controls whether a top border is drawn on tabs for editors that have
  # unsaved changes. This value is ignored when `workbench.editor.showTabs`
  # is not set to multiple.
  "workbench.editor.highlightModifiedTabs" = true;

  # Controls whether scrolling over tabs will open them or not. By default
  # tabs will only reveal upon scrolling, but not open. You can press and
  # hold the Shift-key while scrolling to change this behavior for that
  # duration. This value is ignored when `workbench.editor.showTabs` is not
  # set to `multiple`.
  "workbench.editor.scrollToSwitchTabs" = true;

  # Controls whether tabs should be wrapped over multiple lines when
  # exceeding available space or whether a scrollbar should appear instead.
  # This value is ignored when `workbench.editor.showTabs` is not set to
  # '`multiple`'.
  "workbench.editor.wrapTabs" = true;

  # Controls the size of pinned editor tabs. Pinned tabs are sorted to the
  # beginning of all opened tabs and typically do not close until unpinned.
  # This value is ignored when `workbench.editor.showTabs` is not set to
  # `multiple`.
  #  - normal: A pinned tab inherits the look of non pinned tabs.
  #  - compact: A pinned tab will show in a compact form with only icon or
  #    first letter of the editor name.
  #  - shrink: A pinned tab shrinks to a compact fixed size showing parts of
  #    the editor name.
  "workbench.editor.pinnedTabSizing" = "compact";

  # Controls the size of editor tabs. This value is ignored when
  # `workbench.editor.showTabs` is not set to `multiple`.
  #  - fit: Always keep tabs large enough to show the full editor label.
  #  - shrink: Allow tabs to get smaller when the available space is not
  #    enough to show all tabs at once.
  #  - fixed: Make all tabs the same size, while allowing them to get smaller
  #    when the available space is not enough.
  "workbench.editor.tabSizing" = "shrink";

  # Controls the size of editor groups when splitting them.
  #  - auto: Splits the active editor group to equal parts, unless all editor
  #    groups are already in equal parts. In that case, splits all the editor
  #    groups to equal parts.
  #  - distribute: Splits all the editor groups to equal parts.
  #  - split: Splits the active editor group to equal parts.
  "workbench.editor.splitSizing" = "split";

  # Controls whether editors remain in preview when a code navigation is
  # started from them. Preview editors do not stay open, and are reused
  # until explicitly set to be kept open (via double-click or editing). This
  # value is ignored when `workbench.editor.showTabs` is not set to
  # `multiple`.
  "workbench.editor.enablePreviewFromCodeNavigation" = true;

  # Controls the format of the label for an editor.
  #  - default: Show the name of the file...
  #  - short: Show the name of the file followed by its directory name.
  #  - medium: Show the name of the file followed by its path relative to the
  #    workspace folder.
  #  - long: Show the name of the file followed by its absolute path.
  "workbench.editor.labelFormat" = "short";

  # Controls the format of the label for an untitled editor.
  #  - content: The name of the untitled file is derived from the contents of
  #    its first line unless it has an associated file path.
  #  - name: The name of the untitled file is not derived from the contents
  #    of the file.
  "workbench.editor.untitled.labelFormat" = "name";

  # Overrides colors from the currently selected color theme.
  "workbench.colorCustomizations" = {
    "editorRuler.foreground" = "#4f505a";
  };

  "workbench.settings.alwaysShowAdvancedSettings" = true;
  "workbench.settings.showAISearchToggle" = false;
}
