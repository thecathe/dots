# The prompt's layer segments (modules/home/shell/starship-layers).
#
#  - starship-layers: the behaviour (starship-layers-test.sh): real zsh processes run the
#    hook, the real `starship prompt` draws from the config it picks, and the escape codes
#    are compared with an oracle of the colour rule. Run for the defaults and for a
#    configuration of its own (one shown layer, three colours, kinds sharing a colour).
#    It builds the generated configs, which are copies of one file.
#  - consumer-starship-layers: what reaches the hook from Nix, and what is refused,
#    evaluation only. A second user imports `homeModules.shell` alone, so that is what is
#    evaluated here.
{inputs}: let
  system = "x86_64-linux";
  lib = inputs.nixpkgs.lib;
  dots = inputs.self;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  eval = extra:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          home.username = "consumer";
          home.homeDirectory = "/home/consumer";
          home.stateVersion = "25.11";
        }
        dots.homeModules.shell
        extra
      ];
    };

  defaults = eval {};
  custom = eval {
    dots.shell.starship.layers = {
      maxShown = 1;
      kinds = {
        nix-shell = {
          symbol = "S";
          text = "sh";
          colors = ["#112233" "#445566" "#778899"];
        };
        # shares its first colour with nix-shell's, and its second with direnv's
        nix-develop = {
          symbol = "D";
          text = "dv";
          colors = ["#112233" "#aabbcc"];
        };
        direnv = {
          symbol = "E";
          text = "en";
          colors = ["#AABBCC" "#ddeeff"]; # upper case: compared case-insensitively
        };
      };
      ssh = {
        symbol = "Z";
        text = "rm";
        color = "#0A8A8A";
        # the keys are matched in lower case: Alpha is alpha
        hosts = {
          Alpha = {}; # its host name
          beta = {
            symbol = "b";
            text = "B";
          };
          gamma.symbol = "g"; # its symbol and its host name
          delta.text = "D"; # the default symbol and its string
          epsilon.symbol = ""; # no symbol, its host name
        };
      };
    };
  };
  # the ssh segment off: no ssh configs, nothing exported
  nossh = eval {dots.shell.starship.layers.ssh.enable = false;};

  behaviour = name: hm: let
    layers = hm.config.dots.shell.starship.layers;
    kindsFile = pkgs.writeText "kinds" (lib.concatStrings (lib.mapAttrsToList (kind: k: "${kind}\t${k.symbol}\t${k.text}\t${lib.concatStringsSep " " k.colors}\n") layers.kinds));
    # a string that is not set is @null and an empty one @empty: a tab is whitespace to `read`
    field = v:
      if v == null
      then "@null"
      else if v == ""
      then "@empty"
      else v;
    hostsFile = pkgs.writeText "ssh-hosts" (lib.concatStrings (lib.mapAttrsToList (host: h: "${host}\t${field h.symbol}\t${field h.text}\n") layers.ssh.hosts));
  in
    pkgs.runCommand "starship-layers-${name}" {
      nativeBuildInputs = [hm.config.programs.starship.package pkgs.zsh pkgs.direnv pkgs.gnused pkgs.diffutils pkgs.coreutils];
      LAYERS = layers.package;
      BASE = hm.config.home.file.${hm.config.programs.starship.configPath}.source;
      KINDS = kindsFile;
      MAX = toString layers.maxShown;
      SSH_ENABLED =
        if layers.ssh.enable
        then "1"
        else "0";
      SSH_SYMBOL = layers.ssh.symbol;
      SSH_TEXT = layers.ssh.text;
      SSH_COLOR = layers.ssh.color;
      SSH_HOSTS = hostsFile;
    } ''
      bash ${./starship-layers-test.sh}
      touch $out
    '';

  # (A store path in a string carries context, which `match` refuses.)
  has = needle: hay: lib.hasInfix (builtins.unsafeDiscardStringContext needle) (builtins.unsafeDiscardStringContext hay);

  # An evaluation that has to fail.
  refused = extra: !(builtins.tryEval (eval extra).activationPackage.drvPath).success;

  assertions = let
    zshInit = defaults.config.programs.zsh.initContent;
    off = eval {dots.shell.starship.layers.enable = false;};
    one = eval {dots.shell.starship.layers.kinds.direnv.colors = ["#98971a"];};
    partial = (eval {dots.shell.starship.layers.kinds.nix-shell.colors = ["#112233" "#445566"];}).config.dots.shell.starship.layers.kinds.nix-shell;
    default = defaults.config.dots.shell.starship.layers.kinds.nix-shell;
  in
    lib.assertMsg (has "${defaults.config.dots.shell.starship.layers.package}/layers.zsh" zshInit)
    "consumer-starship-layers: the hook is not sourced from the zsh init"
    && lib.assertMsg (has "${defaults.config.dots.shell.starship.layers.package}/data.zsh" zshInit)
    "consumer-starship-layers: the data file is not sourced from the zsh init"
    && lib.assertMsg (!(has "layers.zsh" off.config.programs.zsh.initContent))
    "consumer-starship-layers: the hook is still in the zsh init with dots.shell.starship.layers.enable off"
    && lib.assertMsg (partial.colors == ["#112233" "#445566"] && partial.symbol == default.symbol && partial.text == default.text)
    "consumer-starship-layers: setting only the colours of a kind lost its symbol or text"
    && lib.assertMsg (lib.all (p: p.have == p.want) [
      # JSON's \u takes four digits, so a codepoint above U+FFFF is a surrogate pair: \uF08C0 once
      # meant U+F08C and a "0".
      {
        have = defaults.config.dots.shell.starship.layers.ssh.symbol;
        want = builtins.fromJSON ''"\uDB82\uDCC0"'';
      } # U+F08C0
      {
        have = defaults.config.dots.shell.starship.layers.kinds.nix-shell.symbol;
        want = builtins.fromJSON ''"\uF120"'';
      }
      {
        have = defaults.config.dots.shell.starship.layers.kinds.nix-develop.symbol;
        want = builtins.fromJSON ''"\uF0AD"'';
      }
      {
        have = defaults.config.dots.shell.starship.layers.kinds.direnv.symbol;
        want = builtins.fromJSON ''"\uED75"'';
      }
    ])
    "consumer-starship-layers: a default symbol is not the codepoint it names"
    && lib.assertMsg (refused {dots.shell.starship.layers.maxShown = 3;})
    "consumer-starship-layers: maxShown = 3 evaluated (3 shown layers would need hundreds of configs)"
    && lib.assertMsg (refused {dots.shell.starship.layers.kinds.nix-shell.colors = ["red" "#00ff00"];})
    "consumer-starship-layers: a colour that is not #rrggbb evaluated"
    && lib.assertMsg (refused {dots.shell.starship.layers.kinds.nix-shell.symbol = "a(b";})
    "consumer-starship-layers: a symbol with a parenthesis (which a starship format reads) evaluated"
    && lib.assertMsg (refused {dots.shell.starship.layers.kinds.direnv.text = "$x";})
    "consumer-starship-layers: a text with a $ evaluated"
    && lib.assertMsg (!(builtins.tryEval one.activationPackage.drvPath).success)
    "consumer-starship-layers: a kind with a single colour evaluated (a nested layer of it would look like its parent)"
    && lib.assertMsg (!(builtins.tryEval (eval {dots.shell.starship.layers.kinds.direnv.colors = ["#98971a" "#98971A"];}).activationPackage.drvPath).success)
    "consumer-starship-layers: a kind whose two colours are the same one evaluated"
    && lib.assertMsg (refused {dots.shell.starship.layers.ssh.color = "#B16286";})
    "consumer-starship-layers: an ssh colour that is a layer's evaluated (the arrow between them would not show)"
    && lib.assertMsg (!refused {
      dots.shell.starship.layers.ssh = {
        enable = false;
        color = "#b16286";
      };
    })
    "consumer-starship-layers: the ssh colour was checked with the segment off"
    && lib.assertMsg (refused {
      dots.shell.starship.layers.ssh.hosts = {
        Box = {};
        box = {};
      };
    })
    "consumer-starship-layers: two host names that differ only in case evaluated"
    && lib.assertMsg (refused {dots.shell.starship.layers.ssh.hosts."worklaptop.example.net" = {};})
    "consumer-starship-layers: a host name with a dot evaluated (the prompt matches the short name)"
    && lib.assertMsg (refused {dots.shell.starship.layers.ssh.hosts.box.text = "a[b";})
    "consumer-starship-layers: a host's text with a bracket evaluated"
    && lib.assertMsg (refused {dots.shell.starship.layers.ssh.text = "s\\h";})
    "consumer-starship-layers: an ssh text with a backslash evaluated";
in {
  starship-layers = pkgs.linkFarm "starship-layers" [
    {
      name = "defaults";
      path = behaviour "defaults" defaults;
    }
    {
      name = "custom";
      path = behaviour "custom" custom;
    }
    {
      name = "nossh";
      path = behaviour "nossh" nossh;
    }
  ];

  consumer-starship-layers = assert assertions;
    pkgs.writeText "consumer-starship-layers" (builtins.unsafeDiscardStringContext defaults.activationPackage.drvPath);
}
