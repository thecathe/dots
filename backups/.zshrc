# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi


# script aliases
alias vscode="bash ~/bin/launch_vscode_workspace.sh"
alias dots="bash ~/bin/run_dot_manager.sh"
alias reload="source ~/.zshrc"

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/home/cathe/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/cathe/.opam/opam-init/init.zsh' ]] || source '/home/cathe/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration
