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

  entry = lib.types.submodule {
    options = {
      key = lib.mkOption {
        type = lib.types.str;
        description = "Single character that runs this entry. j and k are taken by navigation.";
      };
      label = lib.mkOption {type = lib.types.str;};
      icon = lib.mkOption {
        type = lib.types.str;
        default = "chevron_right";
        description = "Material Symbols icon name.";
      };
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "argv to run (no shell; wrap in `sh -c` if one is needed).";
      };
    };
  };

  keys = map (e: e.key) cfg.entries;
in {
  options.dank.curatedMenu.entries = lib.mkOption {
    type = lib.types.listOf entry;
    description = ''
      Entries of the curated menu (a DMS daemon plugin, opened with
      `dms ipc call curatedMenu toggle`, bound to Mod+A in niri). Hosts can
      append with `dank.curatedMenu.entries = lib.mkAfter [ ... ]`.
    '';
    default = [
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
    ];
  };

  config = {
    assertions = [
      {
        assertion = lib.all (k: builtins.stringLength k == 1 && k != "j" && k != "k") keys;
        message = "dank.curatedMenu: every key must be one character other than j/k (got: ${toString keys})";
      }
      {
        assertion = lib.length (lib.unique keys) == lib.length keys;
        message = "dank.curatedMenu: keys must be unique (got: ${toString keys})";
      }
    ];

    programs.dank-material-shell.plugins.curatedMenu = {
      src = ./plugins/curatedMenu;
      settings.entries = cfg.entries;
    };

    home.packages = [dankUsb];
  };
}
