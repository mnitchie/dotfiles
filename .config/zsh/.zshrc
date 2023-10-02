################################################################################
# NEVER ADD SECRETS TO THIS FILE
# Add to $XDG_CONFIG_HOME/includes/secrets.sh instead
# which is sourced below
################################################################################

################################################################################
# XDG (wiki.archlinux.org/index.php/XDG_Base_Directory_support)
################################################################################
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

################################################################################
# Includes
################################################################################i
if [[ -f $XDG_CONFIG_HOME/includes/secrets.sh ]]; then
  source $XDG_CONFIG_HOME/includes/secrets.sh
fi

if [[ -f $XDG_CONFIG_HOME/includes/aliases.sh ]]; then
  source $XDG_CONFIG_HOME/includes/aliases.sh
fi

if [[ -f $XDG_CONFIG_HOME/includes/strata.sh ]]; then
  source $XDG_CONFIG_HOME/includes/strata.sh
fi

if [[ "$(uname)" == "Linux" ]]; then
  source $XDG_CONFIG_HOME/includes/linux.sh
fi

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

# Remove the aws prompt info stuff on the right side of the terminal
# https://github.com/ohmyzsh/ohmyzsh/discussions/10726#discussioncomment-2252630
aws_prompt_info(){}

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

# for poetry
export PATH=$PATH:$HOME/.poetry/bin
export PATH=$HOME/.local/bin:$PATH

# Python
export PYTHONSTARTUP=$XDG_CONFIG_HOME/.pythonstartup.py

