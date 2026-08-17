{lib, ...}: {
  programs.claude-code = {
    enable = true;
    settings = {
      includeCoAuthoredBy = true; # # why lie?
      effortLevel = "xhigh";
      model = "opus";
      permissions = {
        defaultMode = "plan";
        disableBypassPermissionsMode = "disable";
      };
    };
  };
}
