#!/usr/bin/env bash
# The prompt's layer segments, from the hook to the drawn prompt: real zsh processes (nested,
# as shells are) run modules/home/shell/starship-layers/layers.zsh, which picks one of the
# generated starship configs, and the real `starship prompt` draws from it. What is asserted
# is the escape codes of the drawn prompt (each segment's background, each arrow's pair of
# colours), against an oracle of the colour rule written again here in bash.
#
# Environment (from checks/starship-layers.nix):
#   LAYERS  the generated package (variants/NAME.toml, data.zsh, layers.zsh)
#   BASE    the deployed starship.toml the variants were made from
#   KINDS   one line per kind: name TAB symbol TAB text TAB colours (space separated)
#   MAX     how many layers are shown
set -euo pipefail

nfail=0
bad() {
  echo "FAIL: $*" >&2
  nfail=$((nfail + 1))
}
ok() { echo "ok:   $*"; }
# expect GOT WANT DESCRIPTION
expect() {
  if [[ $1 == "$2" ]]; then ok "$3"; else bad "$3: got '$1', want '$2'"; fi
}

tmp=$(mktemp -d)
export HOME=$tmp USER=tester LOGNAME=tester
mkdir -p "$tmp/work"
cd "$tmp/work"

# The palette entries either side of a layer, from the deployed file itself.
palette() { sed -nE "s/^$1 = \"(#[0-9a-fA-F]{6})\".*/\1/p" "$BASE" | tr A-F a-f; }
orange=$(palette color_orange)
yellow=$(palette color_yellow)
rgb() { printf '%d;%d;%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
base=${BASE##*/}

declare -A symbol text colours
kinds=()
while IFS=$'\t' read -r k s t c; do
  kinds+=("$k")
  symbol[$k]=$s
  text[$k]=$t
  colours[$k]=$(tr A-F a-f <<<"$c")
done <"$KINDS"

# ---- the oracle ------------------------------------------------------------------------
# For a stack of kinds, outermost first: the position in its kind's list of each layer's
# colour (the first colour that differs from the layer outside it).
oracle_idx() {
  local prev="" kind j n
  local -a list
  for kind in "$@"; do
    j=1
    read -ra list <<<"${colours[$kind]}"
    for ((n = 0; n < ${#list[@]}; n++)); do
      if [[ ${list[n]} != "$prev" ]]; then
        j=$((n + 1))
        break
      fi
    done
    printf '%s ' "$j"
    prev=${list[j - 1]}
  done
}
colour_of() { # kind position
  local -a list
  read -ra list <<<"${colours[$1]}"
  printf '%s' "${list[$2 - 1]}"
}
# The name of the config the hook has to choose for a stack (empty for none).
oracle_name() {
  local -a ks=("$@") ix
  read -ra ix <<<"$(oracle_idx "$@")"
  local first=$((${#ks[@]} - MAX)) name="" i
  ((first < 0)) && first=0
  for ((i = first; i < ${#ks[@]}; i++)); do
    name+="${name:+"+"}${ks[i]}.${ix[i]}"
  done
  printf '%s' "$name"
}

# ---- the shells ------------------------------------------------------------------------
# One shell level of a chain: `stage.zsh SNIPPET [ENV SNIPPET]...` loads the hook, takes
# its precmd, runs SNIPPET in this shell (what a `cd` into a direnv directory does), takes
# its precmd again, and then, if there is more, starts the next level as a child with ENV
# added to the environment, as `nix-shell` would. The last level prints the config its
# prompt would be drawn from, and the record of layers.
cat >"$tmp/stage.zsh" <<'EOF'
source $LAYERS/data.zsh
source $LAYERS/layers.zsh
_dots_layers_precmd
eval "$1"
shift
_dots_layers_precmd
if (( $# )); then
  env ${=1} zsh -f "$0" "${@:2}"
else
  print -r -- "${STARSHIP_CONFIG-unset} $DOTS_LAYERS"
fi
EOF
# lv ENV... -- SNIPPET [ENV SNIPPET]...: the first level starts with only ENV (and the base
# prompt config, as home-manager sets it); every later one inherits from the one before.
lv() {
  local -a e=()
  while [[ $1 != -- ]]; do
    e+=("$1")
    shift
  done
  shift
  env -i PATH="$PATH" HOME="$tmp" LAYERS="$LAYERS" STARSHIP_CONFIG="$BASE" "${e[@]}" zsh -f "$tmp/stage.zsh" "$@"
}
# the config's file name and the record, as `lv` prints them
name_and_record() { sed -E "s#^$LAYERS/variants/##; s#^$BASE#$base#"; }

# A chain of kinds, as the environment of a real stack: a nix kind is a child shell with
# its own NIX_BUILD_TOP (nested ones a subdirectory of the outer's, as nix-shell does), and
# direnv is loaded in the shell that is there by then.
chain() {
  local kind top=""
  local -a args=("")
  for kind in "$@"; do
    case $kind in
      nix-shell)
        top="${top:-/tmp}/nix-shell-$RANDOM-$RANDOM"
        args+=("IN_NIX_SHELL=impure NIX_BUILD_TOP=$top" "")
        ;;
      nix-develop)
        top="/tmp/nix-shell.$RANDOM$RANDOM"
        args+=("IN_NIX_SHELL=impure NIX_BUILD_TOP=$top" "")
        ;;
      direnv)
        # loaded in the last shell
        args[${#args[@]} - 1]="export DIRENV_DIR=-/work/$RANDOM"
        ;;
    esac
  done
  lv -- "${args[@]}"
}

# What `starship prompt` draws from a config: the line with the segments.
draw() { STARSHIP_CONFIG=$1 starship prompt --terminal-width=120 | sed -n 2p; }
arrow() { printf '48;2;%s;38;2;%s' "$(rgb "$1")" "$(rgb "$2")"; } # background, foreground

# The prompt drawn from a config shows exactly the layers `kind:position`..., outermost
# first: the first segment keeps its orange, each layer has its own background and its
# arrow carries (its colour, the neighbour's before it), and the last arrow leads into the
# yellow one. Returns nonzero when it does not.
shows() {
  local out rest prev=$orange spec kind c label between
  out=$(draw "$1")
  shift
  rest=$out
  for spec in "$@"; do
    kind=${spec%:*}
    c=$(colour_of "$kind" "${spec#*:}")
    label=" ${symbol[$kind]} ${text[$kind]} "
    # the arrow into the layer: its colour as the background, the neighbour's as the foreground
    [[ $rest == *"$(arrow "$c" "$prev")m"* ]] || return 1
    rest=${rest#*"$(arrow "$c" "$prev")m"}
    [[ $rest == *"$label"* ]] || return 1
    # the label sits on that same background: nothing between the arrow and it changes it
    between=${rest%%"$label"*}
    [[ $between != *"48;2;"* ]] || return 1
    rest=${rest#*"$label"}
    prev=$c
  done
  [[ $rest == *"$(arrow "$yellow" "$prev")m"* ]]
}

# ---- 1. the generated configs ----------------------------------------------------------
n=0
for f in "$LAYERS"/variants/*.toml; do
  n=$((n + 1))
  diff <(sed 2d "$BASE") <(sed 2d "$f") >/dev/null || bad "${f##*/} differs from the deployed config beyond the format line"
done
ok "the $n generated configs differ from the deployed one only in its format line"

if [[ $(draw "$BASE") == *"$(arrow "$yellow" "$orange")m"* ]]; then
  ok "the deployed config draws the first segment orange, leading into the yellow one"
else
  bad "the deployed config does not draw the orange arrow into the yellow one: has the preset changed?"
fi
# every generated config draws as many lines as the deployed one (no stray newline in a segment)
want=$(STARSHIP_CONFIG=$BASE starship prompt --terminal-width=120 | wc -l)
for f in "$LAYERS"/variants/*.toml; do
  got=$(STARSHIP_CONFIG=$f starship prompt --terminal-width=120 | wc -l)
  ((got == want)) || bad "${f##*/} draws $got lines, the deployed config $want"
done

# ---- 2. every stack up to three deep, in real nested shells ------------------------------
# The hook chooses the oracle's config, the file exists, and the prompt it draws shows the
# innermost layers with the right colours. A stack has at most one direnv: the second would
# be the same direnv, which replaces rather than stacks.
before=$nfail
stacks=0
combos=("")
for depth in 1 2 3; do
  next=()
  for c in "${combos[@]}"; do
    for k in "${kinds[@]}"; do next+=("${c:+$c }$k"); done
  done
  combos=("${next[@]}")
  for c in "${combos[@]}"; do
    read -ra stack <<<"$c"
    d=0
    for k in "${stack[@]}"; do [[ $k == direnv ]] && d=$((d + 1)); done
    ((d > 1)) && continue
    got=$(chain "${stack[@]}" | sed -E 's/ .*//')
    name=$(oracle_name "${stack[@]}")
    if [[ $got != "$LAYERS/variants/$name.toml" ]]; then
      bad "stack [$c]: the hook chose ${got#"$LAYERS"/variants/}, the oracle says $name.toml"
      continue
    fi
    [[ -f $got ]] || {
      bad "stack [$c]: $name.toml was not generated"
      continue
    }
    read -ra ix <<<"$(oracle_idx "${stack[@]}")"
    from=$((${#stack[@]} - MAX))
    ((from < 0)) && from=0
    specs=()
    for ((i = from; i < ${#stack[@]}; i++)); do specs+=("${stack[i]}:${ix[i]}"); done
    shows "$got" "${specs[@]}" || bad "stack [$c]: the prompt from $name.toml does not show ${specs[*]}"
    stacks=$((stacks + 1))
  done
done
((nfail == before)) && ok "$stacks stacks of up to three layers: the hook picks the oracle's config, it exists, and it draws the innermost $MAX layers right"

# Nested layers of one kind alternate between the colours, never repeating the one outside.
before=$nfail
for k in "${kinds[@]}"; do
  [[ $k == direnv ]] && continue
  got=$(chain "$k" "$k" "$k" "$k" "$k" | sed -E 's/ .*//')
  [[ $got == "$LAYERS/variants/$(oracle_name "$k" "$k" "$k" "$k" "$k").toml" ]] || bad "five nested $k: the hook chose ${got#"$LAYERS"/variants/}"
done
((nfail == before)) && ok "five nested layers of one kind follow the colour rule"

# ---- 3. no layer, and what a shell inherits ---------------------------------------------
expect "$(lv -- '' | name_and_record)" "$base " "no layer: the deployed config is kept"
expect "$(env -i PATH="$PATH" HOME="$tmp" LAYERS="$LAYERS" zsh -f "$tmp/stage.zsh" '')" "unset " "no layer and no STARSHIP_CONFIG to start with: left unset"

one="nix-shell.1.toml nix-shell:/tmp/nix-shell-7-1"
expect "$(lv IN_NIX_SHELL=pure NIX_BUILD_TOP=/tmp/nix-shell-7-1 -- '' | name_and_record)" "$one" "nix-shell --pure is the nix-shell kind"
expect "$(lv IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell.AbC123 -- '' | name_and_record)" "nix-develop.1.toml nix-develop:/tmp/nix-shell.AbC123" "nix develop is told from nix-shell by the dot in NIX_BUILD_TOP"
expect "$(lv IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell-7-1 -- '' 'FOO=1' '' | name_and_record)" "$one" "a plain subshell in a nix-shell adds no layer"
expect "$(lv "DOTS_LAYERS=made-up:1 nix-shell:/tmp/nix-shell-7-1" IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell-7-1 -- '' | name_and_record)" "nix-shell.1.toml made-up:1 nix-shell:/tmp/nix-shell-7-1" "a layer the hook does not know, in the record, is ignored"
# `nix shell` (the newer command) only puts programs on PATH: nothing marks it
expect "$(lv "PATH=/nix/store/x-hello/bin:$PATH" -- '' | name_and_record)" "$base " "nix shell sets no marker, so no layer is shown"

# A shell started in a direnv directory: direnv was loaded before it, so it is outside the
# shell's own layer, and a child that leaves the directory has no direnv layer any more.
expect "$(lv DIRENV_DIR=-/work -- '' 'IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell-9-9' '' | name_and_record)" "$(oracle_name direnv nix-shell).toml direnv nix-shell:/tmp/nix-shell-9-9" "a nix-shell started in a direnv directory: direnv outside, nix-shell inside"
expect "$(lv DIRENV_DIR=-/work -- '' 'IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell-9-9' 'unset DIRENV_DIR' | name_and_record)" "nix-shell.1.toml direnv nix-shell:/tmp/nix-shell-9-9" "a child that leaves the direnv directory drops the direnv layer"
# direnv loaded inside a nix-shell is the inner layer, and a nix-shell started there goes inside that
expect "$(lv IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell-3-3 -- 'export DIRENV_DIR=-/work' 'NIX_BUILD_TOP=/tmp/nix-shell-3-3/nix-shell-4-4' '' | name_and_record)" "$(oracle_name nix-shell direnv nix-shell).toml nix-shell:/tmp/nix-shell-3-3 direnv nix-shell:/tmp/nix-shell-3-3/nix-shell-4-4" "direnv loaded inside a nix-shell sits inside it, and a nix-shell started there inside that"
# `use flake` leaves a NIX_BUILD_TOP that looks like nix develop's, loaded into a shell that is already running (so that shell's hook
# has seen it) and inherited by a child: not a layer; a real `nix develop` run there is
# shell and in a child that merely inherits it: not a layer; a real `nix develop` run there is
expect "$(lv -- 'export DIRENV_DIR=-/work IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell.flake1' 'FOO=1' '' | name_and_record)" "direnv.1.toml direnv" "the NIX_BUILD_TOP direnv's use flake left is not a nix develop layer, in a child shell either"
expect "$(lv -- 'export DIRENV_DIR=-/work IN_NIX_SHELL=impure NIX_BUILD_TOP=/tmp/nix-shell.flake1' 'NIX_BUILD_TOP=/tmp/nix-shell.develop2' '' | name_and_record)" "$(oracle_name direnv nix-develop).toml direnv nix-develop:/tmp/nix-shell.develop2" "a nix develop run in a use-flake directory is a layer"

# ---- 4. the real direnv -----------------------------------------------------------------
# What marks direnv is DIRENV_DIR, set in a directory with an .envrc: the real direnv, in a
# directory of its own and with a private allow list (nobody's real one is touched). It is set
# for a not-allowed .envrc too (measured with direnv 2.38: all of DIRENV_DIR, _FILE, _DIFF and
# _WATCHES are, and only the content of _DIFF, compressed JSON, tells loaded from blocked), so a
# blocked directory shows the layer as well; telling them apart would take a `direnv status`
# process at every prompt below an .envrc, which is not done. The test pins what is true.
mkdir -p "$tmp/proj/sub" "$tmp/data" "$tmp/cfg" "$tmp/open"
echo 'export FROM_ENVRC=1' >"$tmp/proj/.envrc"
echo 'export FROM_ENVRC=1' >"$tmp/open/.envrc" # never allowed
dx() { env -i PATH="$PATH" HOME="$tmp" XDG_DATA_HOME="$tmp/data" XDG_CONFIG_HOME="$tmp/cfg" "$@"; }
dx direnv allow "$tmp/proj" 2>/dev/null
got=$(dx LAYERS="$LAYERS" STARSHIP_CONFIG="$BASE" zsh -f -c '
  source $LAYERS/data.zsh; source $LAYERS/layers.zsh
  show() { eval "$(direnv export zsh 2>/dev/null)"; _dots_layers_precmd; print -r -- "$1 ${STARSHIP_CONFIG:t}${FROM_ENVRC:+ $FROM_ENVRC}"; }
  cd '"$tmp"'/proj/sub; show inside
  cd '"$tmp"'/open;     show not-allowed
  cd '"$tmp"';          show outside
  cd '"$tmp"'/proj;     show again' 2>/dev/null)
want="inside direnv.1.toml 1
not-allowed direnv.1.toml
outside $base
again direnv.1.toml 1"
expect "$got" "$want" "the real direnv: its layer shows while an .envrc is loaded (in a subdirectory too) and goes when it unloads"

rm -rf "$tmp"
echo
((nfail == 0)) && echo "starship-layers: all checks passed" || echo "starship-layers: $nfail failed" >&2
exit $((nfail != 0))
