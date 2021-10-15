alias ..='cd ..'
alias ...='cd ../..'
alias l='ls -lh'
alias ll='ls -alh'

alias stl="sudo systemctl"
alias jtl="sudo journalctl"

# Docker aliases
alias dc='docker container'
alias di='docker image'
alias dl='docker logs'
alias dn='docker network'
alias dx='docker exec -it'
alias dca="docker container ls -a"
alias drr="docker run --rm"
alias dis="docker inspect"
alias dco="docker compose"

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

    PS1="${red}server-name $reset[\w] \$ "
}

function get_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

function gpl() {
        branch=$(get_git_branch)
        echo "Pulling from $branch"
        git pull origin $branch
}

function gac () {
        git add .
        sum=""
        space=" "
        for i do
            sum=$sum$space$i
        done
        git commit -m "${sum}"
}