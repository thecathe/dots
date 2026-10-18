{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dank.curatedMenu;
  dms = "${config.programs.dank-material-shell.package}/bin/dms";

  # Mounts every unmounted filesystem on a hotplug drive, or unmounts and powers
  # off every hotplug drive, so USB sticks need no bar widget (usbManager's
  # popout only exists while it sits on a bar). udisksctl comes from the host,
  # as for usbManager (see dms.nix): it must match the system udisksd.
  dankUsb = pkgs.writeShellScriptBin "dank-usb" ''
    set -u
    notify() { ${pkgs.libnotify}/bin/notify-send -a dank-usb -t 5000 "$@"; }
    lsblk() { ${pkgs.util-linux}/bin/lsblk -J -o PATH,TYPE,HOTPLUG,FSTYPE,MOUNTPOINT "$@"; }
    # lsblk prints hotplug as a JSON boolean (older util-linux: "1").
    hot='(.hotplug == true or .hotplug == "1")'

    case "''${1:-}" in
      mount)
        mapfile -t devs < <(lsblk | ${pkgs.jq}/bin/jq -r "
          .blockdevices[] | select($hot) | ., (.children // [])[]
          | select(.fstype != null and .mountpoint == null) | .path")
        [ "''${#devs[@]}" -gt 0 ] || { notify "USB" "Nothing to mount"; exit 0; }
        for d in "''${devs[@]}"; do
          if out=$(udisksctl mount -b "$d" 2>&1); then notify "USB mounted" "$out"
          else notify -u critical "USB mount failed" "$d: $out"; fi
        done
        ;;
      eject)
        mapfile -t disks < <(lsblk -d | ${pkgs.jq}/bin/jq -r ".blockdevices[] | select($hot) | .path")
        [ "''${#disks[@]}" -gt 0 ] || { notify "USB" "No USB drives"; exit 0; }
        for disk in "''${disks[@]}"; do
          mapfile -t mounted < <(lsblk "$disk" | ${pkgs.jq}/bin/jq -r "
            .blockdevices[] | ., (.children // [])[] | select(.mountpoint != null) | .path")
          for d in "''${mounted[@]}"; do
            out=$(udisksctl unmount -b "$d" 2>&1) || { notify -u critical "USB unmount failed" "$d: $out"; continue 2; }
          done
          if out=$(udisksctl power-off -b "$disk" 2>&1); then notify "USB" "$disk can be removed"
          else notify -u critical "USB power-off failed" "$disk: $out"; fi
        done
        ;;
      *)
        echo "usage: dank-usb mount|eject" >&2
        exit 2
        ;;
    esac
  '';

  # Generator for the "Display profiles" submenu (`menu` prints its entries as
  # JSON, read fresh each time the submenu opens), and the actions those
  # entries run, which report DMS's answer as a toast. Goes through DMS's
  # `outputs` IPC, the documented interface, not its internal QML state.
  dankDisplayProfiles = pkgs.writeShellScriptBin "dank-display-profiles" ''
    set -u
    self=$(readlink -f "$0")
    dms=${dms}
    report() { # $1: IPC reply; PROFILE_SET_SUCCESS is the only success shape
      case "$1" in
        PROFILE_SET_SUCCESS:*) "$dms" ipc call toast info "Display profile:''${1#PROFILE_SET_SUCCESS:}" >/dev/null ;;
        *) "$dms" ipc call toast error "$1" >/dev/null ;;
      esac
    }

    case "''${1:-}" in
      menu)
        # listProfiles prints "No profiles configured" or one line per
        # profile: NAME[ [active,matched]] -> ["DP-1",...]
        list=$("$dms" ipc call outputs listProfiles)
        auto=$("$dms" ipc call outputs status | ${pkgs.gnused}/bin/sed -n 's/^auto: //p')
        printf '%s\n' "$list" | ${pkgs.jq}/bin/jq -R -s \
          --arg self "$self" --arg dms "$dms" --arg auto "$auto" '
          [split("\n")[] | select(test(" -> \\[")) |
            capture("^(?<name>.*?)(?: \\[(?<flags>[a-z,]+)\\])? -> \\[.*\\]$")] as $p
          | if ($p | length) == 0 then
              [{key: "d", label: "No display profiles: open Display configuration",
                icon: "display_settings",
                command: [$dms, "ipc", "call", "settings", "openWith", "display_config"]}]
            else
              [{key: "n", label: "Next profile", icon: "sync", command: [$self, "cycle"]},
               {key: "a", label: "Automatic selection: \($auto) (toggle)", icon: "auto_mode",
                command: [$self, "auto"]}]
              + [$p | to_entries[]
                 | ((.value.flags // "") | split(",") | any(. == "active")) as $active
                 | {key: (if .key < 9 then (.key + 1 | tostring) else "" end),
                    label: (.value.name + (if $active then " (active)" else "" end)),
                    icon: (if $active then "check_circle" else "monitor" end),
                    command: [$self, "set", .value.name]}]
            end'
        ;;
      set) report "$("$dms" ipc call outputs setProfile "''${2:?profile name}")" ;;
      cycle) report "$("$dms" ipc call outputs cycleProfile)" ;;
      auto) "$dms" ipc call toast info "$("$dms" ipc call outputs toggleAuto)" >/dev/null ;;
      *)
        echo "usage: dank-display-profiles menu|set NAME|cycle|auto" >&2
        exit 2
        ;;
    esac
  '';

  # Shared by top-level entries and the entries of a static submenu.
  commonOptions = {
    key = lib.mkOption {
      type = lib.types.str;
      description = "Single character that picks this entry. j and k are taken by navigation.";
    };
    label = lib.mkOption {type = lib.types.str;};
    icon = lib.mkOption {
      type = lib.types.str;
      default = "chevron_right";
      description = "Material Symbols icon name.";
    };
    command = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "argv to run (no shell; wrap in `sh -c` if one is needed).";
    };
  };

  # Submenus nest one level only: a recursive type would make the option docs
  # recurse forever.
  subEntry = lib.types.submodule {options = commonOptions;};
  entry = lib.types.submodule {
    options =
      commonOptions
      // {
        entries = lib.mkOption {
          type = lib.types.listOf subEntry;
          default = [];
          description = "Static submenu.";
        };
        generator = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          description = ''
            argv run each time the submenu opens; it prints a JSON array of
            entries ({key, label, icon, command}) on stdout.
          '';
        };
      };
  };

  # Every level the menu can show (generator output is checked at runtime).
  levels = [cfg.entries] ++ map (e: e.entries) (lib.filter (e: e.entries != []) cfg.entries);
  badKeys = lib.concatMap (l: lib.filter (k: builtins.stringLength k != 1 || k == "j" || k == "k") (map (e: e.key) l)) levels;
  dupLevels = lib.filter (l: let ks = map (e: e.key) l; in lib.length (lib.unique ks) != lib.length ks) levels;
  actions = e: lib.count lib.id [(e.command != null) (e.entries != []) (e.generator != null)];
  badEntries = lib.filter (e: actions e != 1) cfg.entries ++ lib.filter (e: e.command == null) (lib.concatMap (e: e.entries) cfg.entries);

  # The plugin gets only the fields that are set.
  clean = e:
    lib.filterAttrs (_: v: v != null && v != []) (e // lib.optionalAttrs (e ? entries) {entries = map clean e.entries;});
in {
  options.dank.curatedMenu.entries = lib.mkOption {
    type = lib.types.listOf entry;
    description = ''
      Entries of the curated menu (a DMS daemon plugin, opened with
      `dms ipc call curatedMenu toggle`, bound to Mod+A in niri). Each entry
      has exactly one of `command`, `entries` (a static submenu) or
      `generator` (a submenu built when it opens). The defaults below are a
      normal definition, not the option default, so any other definition
      appends to them (`lib.mkAfter`/`lib.mkBefore` to place it) and
      `lib.mkForce` replaces them. See plugins/curatedMenu/README.md.
    '';
  };

  config = {
    dank.curatedMenu.entries = [
      {
        key = "c";
        label = "Colour picker";
        icon = "colorize";
        command = [dms "ipc" "call" "color-picker" "open"];
      }
      {
        key = "n";
        label = "Notepad";
        icon = "edit_note";
        command = [dms "ipc" "call" "notepad" "toggle"];
      }
      {
        key = "v";
        label = "Clipboard history";
        icon = "content_paste";
        command = [dms "ipc" "call" "clipboard" "toggle"];
      }
      {
        key = "u";
        label = "Mount USB drives";
        icon = "usb";
        command = ["${dankUsb}/bin/dank-usb" "mount"];
      }
      {
        key = "e";
        label = "Eject USB drives";
        icon = "eject";
        command = ["${dankUsb}/bin/dank-usb" "eject"];
      }
      {
        key = "d";
        label = "Display configuration";
        icon = "display_settings";
        # Settings > Displays > Configuration (tab ids: `dms ipc call settings tabs`).
        command = [dms "ipc" "call" "settings" "openWith" "display_config"];
      }
      {
        key = "p";
        label = "Display profiles";
        icon = "monitor";
        generator = ["${dankDisplayProfiles}/bin/dank-display-profiles" "menu"];
      }
    ];

    assertions = [
      {
        assertion = badKeys == [];
        message = "dank.curatedMenu: every key must be one character other than j/k (bad: ${toString badKeys})";
      }
      {
        assertion = dupLevels == [];
        message = "dank.curatedMenu: keys must be unique within each menu level";
      }
      {
        assertion = badEntries == [];
        message = "dank.curatedMenu: each entry needs exactly one of command, entries or generator (submenu entries: command) (bad: ${toString (map (e: e.label) badEntries)})";
      }
    ];

    programs.dank-material-shell.plugins.curatedMenu = {
      src = ./plugins/curatedMenu;
      settings.entries = map clean cfg.entries;
    };

    home.packages = [dankUsb dankDisplayProfiles];
  };
}
