################################################################################
# Includes
################################################################################
if [[ -f $HOME/.config/.secrets.sh ]]; then
  source $HOME/.config/secrets.sh
fi

if [[ -f $HOME/.config/.aliases.sh ]]; then
  source $HOME/.config/aliases.sh
fi

################################################################################
# XDG (wiki.archlinux.org/index.php/XDG_Base_Directory_support)
################################################################################
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

# Python
export PYTHONSTARTUP=$HOME/.pythonrc

################################################################################
# ZSH
################################################################################
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git gitfast aws zsh-autosuggestions docker docker-compose)
source $ZSH/oh-my-zsh.sh

# Remove the username@host prefix from the agnoster prompt
prompt_context(){}

# .oh-my-zsh/lib/misc.zsh sets the pager to something I don't want. Set it back to the default
export PAGER=less
unset LESS

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

################################################################################
# General configs
################################################################################
# Prevent commands preceeded by a leading space from ending up in history
setopt HIST_IGNORE_SPACE

# Preferred editor for local and remote sessions
export EDITOR='vim'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# for poetry
export PATH=$PATH:$HOME/.poetry/bin
export PATH=$HOME/.local/bin:$PATH
