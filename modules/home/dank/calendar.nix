{...}: {
  # DankCalendar (dcal): calendar app + background sync daemon (tray icon,
  # event reminders) for Local/Google/Microsoft/CalDAV/iCloud calendars.
  # Module comes from the dcal flake input (homeModules.default, wired in
  # flake.nix); the service is `dcal run --session --hidden`, i.e. it starts
  # to the tray and closing the window only hides it.
  #
  # Accounts are added interactively and are not declarative:
  #   dcal account add local|caldav|google|microsoft
  # Google/Microsoft open a browser sign-in. OAuth tokens and secrets go to the
  # system keyring (org.freedesktop.secrets), so a secret service has to be
  # running on the host - gnome-keyring is on the Ubuntu host, nothing in this
  # repo provides one for the NixOS hosts.
  #
  # `settings` (-> ~/.config/dankcal/ui-settings.json) is left unset on
  # purpose: the module would write it as a read-only store symlink, and the
  # app persists UI preferences (reminder defaults, 24h clock, ...) there
  # itself.
  programs.dank-calendar = {
    enable = true;
    systemd.enable = true;
  };
}
