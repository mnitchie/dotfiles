alias history="history -f 0"
alias ls=exa # `brew install exa`` if needed
alias temp=sudo powermetrics --samplers smc | egrep -i "temp|fan"
alias tree=tree -C
alias sqlite3='sqlite3 -init $XDG_CONFIG_HOME/.sqliterc'