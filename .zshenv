# Make sure zsh knows where to look for zshrc files n' stuff
export ZDOTDIR=$HOME/.config/zsh

# Add the main alias for the dotfiles repo
alias config='/usr/bin/git --git-dir=$HOME/.my_dotfiles_git --work-tree=$HOME'