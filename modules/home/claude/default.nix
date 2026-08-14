{ lib, ... }: {
  programs.claude-code = {
    enable = true;
    settings = {
      includeCoAuthoredBy = true; # # why lie?
    };
  };
}
