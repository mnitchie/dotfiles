# TODO rethink this
if [[ -f ~/secrets.sh ]]; then
  source ~/secrets.sh
fi

if [[ -f ~/aliases.sh ]]; then
  source ~/aliases.sh
fi

# XDG (wiki.archlinux.org/index.php/XDG_Base_Directory_support)
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

export PYTHONSTARTUP=$HOME/.pythonrc

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

bgnotify_threshold=4  ## set your own notification threshold
function bgnotify_formatted {
  ## $1=exit_status, $2=command, $3=elapsed_time
  [ $1 -eq 0 ] && title="Holy Smokes Batman!" || title="Holy Graf Zeppelin!"
  bgnotify "$title -- after $3 s" "$2";
}

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git bgnotify gitfast aws zsh-autosuggestions docker docker-compose)
source $ZSH/oh-my-zsh.sh

# .oh-my-zsh/lib/misc.zsh sets the pager to something I don't want. Set it back to the default
export PAGER=less
unset LESS

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Remove the username@host prefix from the agnoster prompt
prompt_context(){}

export PATH=$PATH:$HOME/.poetry/bin

# MIKE UPDATE: Prevent commands preceeded by a leading space from ending up in history
setopt HIST_IGNORE_SPACE

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

# for poetry
export PATH=$HOME/.local/bin:$PATH
