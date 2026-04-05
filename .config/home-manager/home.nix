{
  config,
  pkgs,
  # thenixuser ? import /home/cathe/dots/user.nix
  ...
}:

let
  # thenixuser = builtins.fromJSON (builtins.readFile "/home/${config.home.username}/dots/user.json");
  # thenixuser = builtins.readFile "/home/${config.home.username}/dots/user.nix";
  thenixuser = import /home/cathe/dots/user.nix { inherit pkgs; };
in
{

  # NOTE: this is symlinked so theres one less ../
  # thenixuser = import "${../../dots/user.nix}" {inherit pkgs;};
  # thenixuser = import "/home/${config.home.username}/dots/user.nix" {inherit pkgs;};

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = thenixuser.username;
  home.homeDirectory = "/home/${thenixuser.username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    nixfmt

    zsh # -powerlevel9k
    powerline
    git
    gh
    #    nix
    #    nix-index
    #   nix-diff
    #   neovim
    #vimPlugins.coc-nvim
    alacritty
    hyprland
    ags
    #   sway
    #    swaylock
    #steam
    prismlauncher
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cathe/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # nix
  #nix.settings.experimental-features = [ "nix-command" ];
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # git config
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings.user = {
      name = thenixuser.username;
      email = thenixuser.email;
    };
  };

  # Zsh config
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };

    setOptions = [
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_SAVE_NO_DUPS"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_SPACE"
      "APPENDHISTORY"
      "SHARE_HISTORY"
      "HIST_FCNTL_LOCK"
    ];

    #    shellAliases = {
    #      ll = "ls -l";
    #      update = "sudo nixos-rebuild switch";
    #    };
  };

  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = [ "git" ];
    theme = thenixuser.theme.zsh;
  };

  #  programs.steam.enable = true;

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    coc.enable = true;
  };

  #  programs.neovim.coc = {
  #    enable = true;
  #  };

}
