alias ..='cd ..'
alias ...='cd ../..'
alias l='ls -lh'
alias ll='ls -alh'

alias stl="sudo systemctl"

# Docker aliases
alias dc='docker container'
alias di='docker image'
alias dl='docker logs'
alias dn='docker network'
alias de='docker exec -it'
alias dca="docker container ls -a"
alias dco="docker-compose"

function dis() {
    docker inspect $1 | jq ".[0].$2"
}

# Git aliases
alias gs='git status'
alias gb='git branch '
alias gco='git checkout'
alias gd='git diff'
alias gl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Mixed
alias td="sudo tcpdump -tnn"

# PROMPT_COMMAND=build_prompt
function build_prompt() {
    red='\[\e[1;31m\]'
    green='\[\e[1;32m\]'
    yellow='\[\e[1;33m\]'
    blue='\[\e[1;34m\]'
    magenta='\[\e[1;35m\]'
    cyan='\[\e[1;36m\]'
    reset='\[\e[0m\]'

    PS1="${red}PLATFORM-PRODUCTION $reset[\w] \$ "
}
