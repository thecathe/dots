# A mark in the prompt for each environment layer the shell is in (nix-shell, nix develop,
# direnv), each its own starship segment between the first (orange) one and the directory.
#
# Starship cannot take a segment's colour from a variable, and the arrows either side of a
# segment carry its colour and its neighbour's. So Nix writes one starship config for every
# state the prompt can be in (the deployed one with the layer segments spliced in; see
# default.nix) and a `precmd` hook, defined here, points STARSHIP_CONFIG at the right one
# before each prompt. Nothing here starts a process.
#
# Sourced after data.zsh, which defines:
#   _dots_layers_dir     the directory of the generated configs (NAME.toml)
#   _dots_layers_max     how many layers are shown (the innermost ones)
#   _dots_layer_colors   kind -> its colours, a space-separated list (the colour rule below)
#   _dots_ssh            1 if the ssh segment is on
#   _dots_ssh_symbol, _dots_ssh_text   its default label
#   _dots_ssh_hosts, _dots_ssh_host_symbol, _dots_ssh_host_text   the machines (lower case,
#                        short names) that show something else, and what: see the ssh options
#
# State, all exported so that a child shell inherits it and the parent's environment is
# never touched (so leaving a shell restores the outer prompt with no code at all):
#   DOTS_LAYERS         the layers outside and in this shell, outermost first, as words
#                       "kind" or "kind:key", where the key is what tells two layers of
#                       one kind apart (the nix kinds' NIX_BUILD_TOP). direnv has no key.
#   DOTS_STARSHIP_BASE  the starship config of a shell with no layer. STARSHIP_CONFIG
#                       itself cannot be the base: a child inherits the parent's choice.
#   DOTS_DIRENV_TOP     NIX_BUILD_TOP as it was while direnv was loaded (see _record).
#   DOTS_SSH_LABEL      what the ssh segment shows (a generated config reads it), set while this
#                       is an ssh session: the segment is not a layer of the stack, it is drawn
#                       first, does not count towards _dots_layers_max, and is looked at at every
#                       prompt like direnv.

# Is the layer `$1` (a whole word) in DOTS_LAYERS?
_dots_layers_has() {
  [[ " ${DOTS_LAYERS-} " == *" $1 "* ]]
}

# Once per shell, from the environment it was started in: append to DOTS_LAYERS the layers
# that environment carries and the list does not know yet. A plain `zsh` typed inside a
# layer inherits the same keys and so adds nothing.
_dots_layers_record() {
  local kind

  # direnv first: if it is loaded here it was loaded before this shell started, so it is
  # outside whatever layer this shell is itself.
  if [[ -n ${DIRENV_DIR-} ]] && ! _dots_layers_has direnv; then
    DOTS_LAYERS+="${DOTS_LAYERS:+ }direnv"
  fi

  # The nix layer of this shell. `nix-shell` has NIX_BUILD_TOP=/tmp/nix-shell-<pid>-<n>,
  # `nix develop` /tmp/nix-shell.<random>; a nested nix-shell's is a subdirectory of the
  # outer one's, hence the last component. A direnv `use flake` directory carries
  # `nix develop`'s variables exactly, and `use flake` is not a layer of its own, so the
  # NIX_BUILD_TOP that direnv set (DOTS_DIRENV_TOP) is left out.
  if [[ -n ${IN_NIX_SHELL-} && -n ${NIX_BUILD_TOP-} && $NIX_BUILD_TOP != ${DOTS_DIRENV_TOP-} ]]; then
    case ${NIX_BUILD_TOP:t} in
      nix-shell-*) kind=nix-shell ;;
      nix-shell.*) kind=nix-develop ;;
    esac
    if [[ -n $kind && " $DOTS_LAYERS " != *":$NIX_BUILD_TOP "* ]]; then
      DOTS_LAYERS+="${DOTS_LAYERS:+ }$kind:$NIX_BUILD_TOP"
    fi
  fi
}

# Before every prompt: which config the prompt is drawn from.
_dots_layers_precmd() {
  # direnv comes and goes as you `cd`, so it is looked at every time. A shell started from
  # here must be able to tell direnv's NIX_BUILD_TOP from its own (see _record).
  if [[ -n ${DIRENV_DIR-} ]]; then
    export DOTS_DIRENV_TOP=${NIX_BUILD_TOP-}
  else
    unset DOTS_DIRENV_TOP
  fi

  # ssh: sshd sets SSH_CONNECTION, so this shell was started by someone ssh'ing into this
  # machine (and its children inherit it). The prompt is drawn here, so the host name to look
  # up is this machine's own: short, in lower case. A machine in the table shows its host name
  # unless it gives another string, and the default symbol unless it gives another.
  local ssh=
  if (( _dots_ssh )) && [[ -n ${SSH_CONNECTION-} ]]; then
    local host=${HOST%%.*} symbol=$_dots_ssh_symbol text=$_dots_ssh_text
    local key=${(L)host}
    if (( ${+_dots_ssh_hosts[$key]} )); then
      (( ${+_dots_ssh_host_symbol[$key]} )) && symbol=${_dots_ssh_host_symbol[$key]}
      text=${_dots_ssh_host_text[$key]-$host}
    fi
    export DOTS_SSH_LABEL="${symbol:+$symbol }$text"
    ssh=ssh
  else
    unset DOTS_SSH_LABEL
  fi

  # The layers there are now, outermost first. A recorded direnv layer is there only while
  # direnv is loaded; one loaded since this shell started is the innermost.
  local entry kind
  local -a kinds
  for entry in ${=DOTS_LAYERS}; do
    kind=${entry%%:*}
    [[ -n ${_dots_layer_colors[$kind]-} ]] || continue
    [[ $kind == direnv && -z ${DIRENV_DIR-} ]] && continue
    kinds+=($kind)
  done
  if [[ -n ${DIRENV_DIR-} ]] && ! _dots_layers_has direnv; then
    kinds+=(direnv)
  fi

  # The colour rule: a layer takes the first colour of its kind's list that differs from the
  # layer directly outside it, so a nested layer never looks like its parent and a kind is
  # still recognisable. It is the index in the list that is kept (it names the config).
  local prev= j n
  local -a colors idx
  for kind in $kinds; do
    colors=(${=_dots_layer_colors[$kind]})
    j=1
    for (( n = 1; n <= $#colors; n++ )); do
      if [[ ${colors[n]} != $prev ]]; then
        j=$n
        break
      fi
    done
    idx+=($j)
    prev=${colors[j]}
  done

  # The innermost `_dots_layers_max` are shown, after the ssh segment if there is one.
  local first=$(( $#kinds - _dots_layers_max + 1 )) name=$ssh i
  (( first < 1 )) && first=1
  for (( i = first; i <= $#kinds; i++ )); do
    name+="${name:+"+"}${kinds[i]}.${idx[i]}"
  done

  local target=${DOTS_STARSHIP_BASE-}
  [[ -n $name ]] && target=$_dots_layers_dir/$name.toml
  if [[ -n $target ]]; then
    export STARSHIP_CONFIG=$target
  else
    unset STARSHIP_CONFIG
  fi
}

_dots_layers_init() {
  autoload -Uz add-zsh-hook
  if (( ! ${+DOTS_STARSHIP_BASE} )); then
    export DOTS_STARSHIP_BASE=${STARSHIP_CONFIG-}
  fi
  export DOTS_LAYERS=${DOTS_LAYERS-}
  _dots_layers_record
  add-zsh-hook precmd _dots_layers_precmd
}

_dots_layers_init
