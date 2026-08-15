let
  editor = import ./editor.nix;
  explorer = import ./explorer.nix;
  extensions = import ./extensions.nix;
  terminal = import ./terminal.nix;
  workbench = import ./workbench.nix;
in
  editor
  // explorer
  // extensions
  // terminal
  // workbench
  // {
    # When enabled, will trim trailing whitespace when saving a file.
    "files.trimTrailingWhitespace" = true;

    # When enabled shows the current problem in the status bar.
    "problems.showCurrentInStatus" = true;

    # Controls the font size (in pixels) of the screencast mode keyboard.
    # "screencastMode.fontSize" = 64.0;

    # Controls how to handle opening untrusted files in a trusted workspace. This
    # setting also applies to opening files in an empty window which is trusted
    # via `security.workspace.trust.emptyWindow`.
    #  - prompt: Ask how to handle untrusted files for each workspace.
    #  - open: Always allow untrusted files without prompting.
    #  - newWindow: Always open untrusted files in a separate restricted window.
    "security.workspace.trust.untrustedFiles" = "open";

    # Specifies the profile to use when opening a new window. If a profile name
    # is provided, the new window will use that profile. If no profile name is
    # provided, the new window will use the profile of the active window or the
    # Default profile if no active window exists.
    "window.newWindowProfile" = "Default";

    # Controls whether turning on Zen Mode also hides the editor line numbers.
    "zenMode.hideLineNumbers" = false;

    # debug.console.*
    # Controls the font size in pixels in the Debug Console.
    # "debug.console.fontSize" = 16.0;

    # Controls the font family in the Debug Console.
    "debug.console.fontFamily" = "JetBrainsMono Nerd Font Mono";

    # notebook.*
    # Controls when the Markdown header folding arrow is shown.
    #  - always: The folding controls are always visible.
    #  - never: Never show the folding controls and reduce the gutter size.
    #  - mouseover: The folding controls are visible only on mouseover.
    "notebook.showFoldingControls" = "always";

    # Controls the font family of rendered markup in notebooks. When left
    # blank, this will fall back to the default workbench font family.
    "notebook.markup.fontFamily" = "UbuntuSans Nerd Font";

    # chat.*
    # Controls whether the Open in Agents Window button is shown in the title bar.
    "chat.titleBar.openInAgentsWindow.enabled" = false;

    # Enables chat participant autodetection for panel chat.
    "chat.detectParticipant.enabled" = false;

    # Controls the font family in chat messages.
    "chat.fontFamily" = "UbuntuSans Nerd Font";

    # Controls the font size in pixels in chat codeblocks.
    # "chat.editor.fontSize" = 16.0;

    # Controls the font family in chat codeblocks.
    "chat.editor.fontFamily" = "JetBrainsMono Nerd Font Mono";

    # http.*
    # The value to send as the `Proxy-Authorization` header for every network
    # request. When during remote development the
    # `http.useLocalProxyConfiguration` setting is disabled this setting can be
    # configured in the local and the remote settings separately.
    "http.proxyAuthorization" = null;

    # Controls whether the proxy server certificate should be verified against
    # the list of supplied CAs.
    "http.proxyStrictSSL" = true;

    # Use the proxy support for extensions.
    #  - off: Disable proxy support for extensions.
    #  - on: Enable proxy support for extensions.
    #  - fallback: Enable proxy support for extensions, fall back to request
    #    options, when no proxy found.
    #  - override: Enable proxy support for extensions, override request options.
    "http.proxySupport" = "off";
  }
