export PS1='\n\u@\h\n${PWD}\nsh>'
alias ll='ls -l'
alias lla='ls -la'
alias install='sudo pacman -S'
alias uninstall='sudo pacman -R'
alias update='sudo pacman -Syu'
alias reboot='sudo shutdown -r now'
alias shutdown='sudo shutdown -h now'

[ -f /usr/bin/env.sh ] && . /usr/bin/env.sh
