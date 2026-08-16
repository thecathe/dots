{
  config,
  lib,
  ...
}: let
  aliasDir = "${config.home.homeDirectory}/dots/modules/home/shell/zsh";
in {
  programs.zsh.initContent = lib.mkOrder 1200 ''
    ## ensure files exist
    for f in aliases.dots.zsh aliases.local.zsh dirs.dots.zsh dirs.local.zsh; do
      [[ -f ${aliasDir}/$f ]] || : > ${aliasDir}/$f
    done

    _binding-write() {
      local prefix="$1" file="$2" name="$3" value="$4"
      [[ -f "$file" ]] && sed -i "/^''${prefix} ''${name}=/d" "$file"
      printf '%s %s=%s\n' "$prefix" "$name" "''${(qq)value}" >> "$file"
    }
    _binding-delete() {
      local prefix="$1" file="$2" name="$3"
      [[ -f "$file" ]] && sed -i "/^''${prefix} ''${name}=/d" "$file"
    }

    ## alias files
    [[ -f ${aliasDir}/aliases.dots.zsh ]] && source ${aliasDir}/aliases.dots.zsh   ## initial dot aliases
    [[ -f ${aliasDir}/aliases.local.zsh ]] && source ${aliasDir}/aliases.local.zsh  ## local overrides

    alias-set() {
      local scope=dots ## default (optiona=local)
      [[ "$1" == "--local" ]] && { scope=local; shift }
      local name="$1"; shift
      [[ -z "$name" || -z "$*" ]] && { echo "usage: alias-set [--local] NAME VALUE..." >&2; return 1 }
      local file="${aliasDir}/aliases.$scope.zsh"

      ## write to file
      _binding-write alias "$file" "$name" "$*"

      ## define alias for use
      alias -- "$name=$*"
      echo "set ($scope): $name -> $*"
    }

    alias-unset() {
      local scope=dots ## default (optiona=local)
      [[ "$1" == "--local" ]] && { scope=local; shift }
      local name="$1" file="${aliasDir}/aliases.$scope.zsh"

      ## remove from file
      _binding-delete alias "$file" "$name"

      ## undefine alias
      unalias "$name" 2>/dev/null
      echo "unset ($scope): $name"
    }

    alias-ls() {
      echo "-- dots (tracked) --";   [[ -f ${aliasDir}/aliases.dots.zsh  ]] && cat ${aliasDir}/aliases.dots.zsh
      echo "-- local (untracked) --"; [[ -f ${aliasDir}/aliases.local.zsh ]] && cat ${aliasDir}/aliases.local.zsh
    }

    ## dhash files
    [[ -f ${aliasDir}/dirs.dots.zsh  ]] && source ${aliasDir}/dirs.dots.zsh
    [[ -f ${aliasDir}/dirs.local.zsh ]] && source ${aliasDir}/dirs.local.zsh

    dhash-set() {
      local scope=dots ## default (optiona=local)
      [[ "$1" == "--local" ]] && { scope=local; shift }
      local name="$1" path="$2"
      [[ -z "$name" || -z "$path" ]] && { echo "usage: dirhash-set [--local] NAME PATH" >&2; return 1 }
      local file="${aliasDir}/dirs.$scope.zsh"

      ## write to file
      _binding-write "hash -d" "$file" "$name" "$path"

      ## define hash for use
      hash -d "$name=$path"
      echo "set ($scope): ~$name -> $path"
    }

    dhash-unset() {
      local scope=dots ## default (optiona=local)
      [[ "$1" == "--local" ]] && { scope=local; shift }
      local name="$1" file="${aliasDir}/dirs.$scope.zsh"

      ## remove from file
      _binding-delete "hash -d" "$file" "$name"

      ## unhash
      unhash -d "$name" 2>/dev/null
      echo "unset ($scope): ~$name"
    }

    dhash-ls() {
      echo "-- dots (tracked) --";   [[ -f ${aliasDir}/dirs.dots.zsh  ]] && cat ${aliasDir}/dirs.dots.zsh
      echo "-- local (untracked) --"; [[ -f ${aliasDir}/dirs.local.zsh ]] && cat ${aliasDir}/dirs.local.zsh
    }
  '';
}
