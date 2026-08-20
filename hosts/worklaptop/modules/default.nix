{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./xmodmap
    # ./shell-overrides
  ];
}
