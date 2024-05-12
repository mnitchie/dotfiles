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

################################################################################
# Pyenv setup
################################################################################
export PYENV_ROOT="$XDG_CONFIG_HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

################################################################################
# Set up aws-vault prompt info. when you do aws-vault exec <profile> --duration=<>
# It will show the active profile and the remaining duration of the session
################################################################################

# Overrides the `prompt_aws` function from the agnoster theme.
# Identical, but it also accounts for the `cleardata` profile
prompt_aws() {
  [[ -z "$AWS_PROFILE" || "$SHOW_AWS_PROMPT" = false ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*|cleardata) prompt_segment red yellow  "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
    *) prompt_segment green black "AWS: ${AWS_PROFILE:gs/%/%%}" ;;
  esac
}

function aws_vault_prompt_info() {
  local profile=$AWS_VAULT
  local expiration=$AWS_CREDENTIAL_EXPIRATION

  if [[ -n $profile && -n $expiration ]]; then
    local now=$(date -u +%s)
    local exp=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$expiration" +%s)
    local remaining=$((exp - now))
    local hours=$((remaining / 3600))
    local minutes=$(((remaining % 3600) / 60))

    case "$profile" in
      *-prod|*production*|cleardata) prompt_segment red yellow "AWS:$profile ($hours:$minutes left)" ;;
      *) prompt_segment green black "$profile ($hours:$minutes left)" ;;
    esac
  fi
}

PROMPT='$(aws_vault_prompt_info)'$PROMPT