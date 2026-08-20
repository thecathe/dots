{
  config,
  pkgs,
  ...
}: {
  home.file.".Xmodmap".text = ''
    # rebind copilot key to ctrl
    keycode 201 = Control_L
  '';

  xsession.initExtra = ''
    xmodmap ~/.Xmodmap
  '';

  ## reported as overkill -- maybe revisit if issues with above
  # systemd.user.services.xmodmap-remap = {
  #   Unit = {
  #     Description = "Remap Copilot button to Ctrl";
  #     After = [ "graphical-session-pre.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.xmodmap}/bin/xmodmap %h/.Xmodmap";
  #     RemainAfterExit = true;
  #   };
  #   Install.WantedBy = [ "graphical-session.target" ];
  # };
}
