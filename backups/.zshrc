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
