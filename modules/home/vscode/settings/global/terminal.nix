{
  # Customizes which terminal to run on Linux.
  "terminal.external.linuxExec" = "kitty";

  # Whether or not to allow chord keybindings in the terminal. Note that when
  # this is true and the keystroke results in a chord it will bypass
  # `terminal.integrated.commandsToSkipShell`, setting this to false is
  # particularly useful when you want ctrl+k to go to your shell (not VS Code).
  "terminal.integrated.allowChords" = false;

  # Controls the font size in pixels of the terminal.
  # "terminal.integrated.fontSize" = 16.0;

  # Controls the maximum number of lines the terminal keeps in its buffer. We
  # pre-allocate memory based on this value in order to ensure a smooth
  # experience. As such, as the value increases, so will the amount of memory.
  "terminal.integrated.scrollback" = 10000;

  # The default terminal profile on Windows.
  "terminal.integrated.defaultProfile.windows" = "Git Bash";

  # The default terminal profile on Linux.
  "terminal.integrated.defaultProfile.linux" = "zsh";
}
