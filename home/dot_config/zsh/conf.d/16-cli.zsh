if (( $+commands[rg] )); then
  grep() {
    print -Pu2 '%F{yellow}grep: try rg%f'
    command grep "$@"
  }
fi

if (( $+commands[duf] )); then
  df() {
    print -Pu2 '%F{yellow}df: try duf%f'
    command df "$@"
  }
fi

if (( $+commands[dust] )); then
  du() {
    print -Pu2 '%F{yellow}du: try dust%f'
    command du "$@"
  }
fi
