if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
fi

if (( $+commands[eza] )); then
  alias ls='eza --icons=always'
fi

if (( $+commands[tree] )); then
  alias tree='tree -C'
fi

if (( $+commands[chezmoi] )); then
  alias editz='chezmoi edit --apply ~/.config/zsh/.zshrc'
fi

# exec replaces this process so Starship, compinit, and fnm init do not stack.
if (( $+commands[zsh] )); then
  alias reloadz='exec zsh'
fi

if (( $+commands[uv] )); then
  alias manage='uv run python manage.py'
fi

if (( $+commands[git] )); then
  gitacp() {
    if [[ -z ${1-} ]]; then
      print -u2 -- 'usage: gitacp <message>'
      return 2
    fi
    git add --all && git commit -m "$1" && git push
  }
fi

if (( $+commands[sed] && $+commands[column] && $+commands[less] )); then
  csv() {
    sed 's/,/ ,/g' "$@" | column -t -s ',' | less -S
  }
fi
