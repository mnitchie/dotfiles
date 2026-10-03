if (( $+commands[fd] )); then
  find() {
    print -Pu2 '%F{#ffd700}find: try fd%f'
    command find "$@"
  }
fi

if (( $+commands[rg] )); then
  grep() {
    print -Pu2 '%F{#ffd700}grep: try rg%f'
    command grep "$@"
  }
fi

if (( $+commands[duf] )); then
  df() {
    print -Pu2 '%F{#ffd700}df: try duf%f'
    command df "$@"
  }
fi

if (( $+commands[dust] )); then
  du() {
    print -Pu2 '%F{#ffd700}du: try dust%f'
    command du "$@"
  }
fi
