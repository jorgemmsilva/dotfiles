###############################
# oh-my-zsh setup
###############################

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  colored-man-pages
  command-not-found
  docker
  npm
  #pip
  #pyenv
  #python
  sudo
  systemd
  zsh-autosuggestions
  zsh-syntax-highlighting
  # fast-syntax-highlighting
  # zsh-autocomplete
  golang
  archlinux
  fzf
)

source $ZSH/oh-my-zsh.sh

###############################
# Aliases
###############################

# ls
alias ls='lsd'
alias l='ls -la'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# alias for SimpleHTTPServer
alias serve="python -m SimpleHTTPServer"

# quick cd to parent
alias ..="cd .."
alias ....="cd ../.."
alias ......="cd ../../.."
alias ........="cd ../../../.."

# misc aliases
# alias nv='nvim'
alias nv='~/mydevcontainer/nv'
alias c='code'

# git aliases
alias gs="git status"
alias gp="git pull"
alias gps="git push"
alias gpsf="git push --force-with-lease"
alias ga="git add -A"
alias gc="git checkout"
alias gprune="git fetch --prune ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -D"
alias gcleantags="git tag -l | xargs git tag -d && git fetch -t"
alias gcleanup="git fetch --prune --prune-tags && git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -D"
alias gl="git log --oneline --decorate --all --graph"

# RUST
alias cargo-features='function _cargo_features() { cargo metadata --format-version=1 | jq --arg pkg "$1" '"'"'.packages[] | select(.name == $pkg) | .features'"'"'; }; _cargo_features'
alias clippy='cargo clippy --workspace --all-targets --all-features --fix --allow-dirty --allow-staged'


###############################
# MISC
###############################

# bun completions
[ -s "/Users/jorge/.bun/_bun" ] && source "/Users/jorge/.bun/_bun"


###############################
# Evals
###############################

# direnv
eval "$(direnv hook zsh)"

# zoxide
eval "$(zoxide init zsh)"

# thefuck
eval "$(thefuck --alias F)"

#####################################
#
# needs to be at the end
eval "$(starship init zsh)"
