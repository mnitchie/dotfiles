alias history="history -f 0"
alias ls=exa # `brew install exa`` if needed
alias temp=sudo powermetrics --samplers smc | egrep -i "temp|fan"
alias tree=tree -C
alias sqlite3='sqlite3 -init $XDG_CONFIG_HOME/.sqliterc'

# Niceties for poking at the .zshrc file
alias sourcez='source $XDG_CONFIG_HOME/zsh/.zshrc'
alias vimz='vim $XDG_CONFIG_HOME/zsh/.zshrc'
alias catz='cat $XDG_CONFIG_HOME/zsh/.zshrc'

# https://github.com/mnitchie/python_sandbox
alias pythond='docker run -it --rm --name python_sandbox python_sandbox bash'
