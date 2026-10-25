{
  config,
  lib,
  ...
}: {
  options.dots.samba.enable = lib.mkEnableOption "Samba file sharing, advertised on the local network (wsdd, avahi)";

  config = lib.mkIf config.dots.samba.enable {
    services = {
      samba = {
        enable = true;
        ## https://gist.github.com/vy-let/a030c1079f09ecae4135aebf1e121ea6
        openFirewall = true;
        # Members of the usershares group can share folders themselves (e.g.
        # from Nautilus); the dots user is added below.
        usershares.enable = true;

        settings = {
          global = {
            "server smb encrypt" = "required";
            "server min protocol" = "SMB3_00";
            "workgroup" = "WORKGROUP";
            "security" = "user";
          };
        };
      };
      samba-wsdd = {
        enable = true;
        openFirewall = true;
      };
      avahi = {
        enable = true;
        publish.enable = true;
        publish.userServices = true;
        openFirewall = true;
      };
    };

    users.users.${config.dots.user.name}.extraGroups = [config.services.samba.usershares.group];
  };
}
