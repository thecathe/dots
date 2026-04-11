{
  ...
}:

{
  enable = true;
  ## https://gist.github.com/vy-let/a030c1079f09ecae4135aebf1e121ea6
  openFirewall = true;
  usershares.enable = true;

  settings = {
    global = {
      "server smb encrypt" = "required";
      "server min protocol" = "SMB3_00";
      "workgroup" = "WORKGROUP";
      "security" = "user";
    };

    testshare = {
      "path" = "/home/cathe/Public";
      "writable" = "yes";
      "comment" = "Hello World!";
      "browseable" = "yes";
    };
  };
}
