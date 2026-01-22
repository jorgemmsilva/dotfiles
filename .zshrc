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

######### misc aliases

# lsd
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


# FASD alias
alias v='f -e nvim' # quick opening files with neo vim
alias nv='nvim'

# VScode alias
alias c='code'

# RUST
alias cargo-features='function _cargo_features() { cargo metadata --format-version=1 | jq --arg pkg "$1" '"'"'.packages[] | select(.name == $pkg) | .features'"'"'; }; _cargo_features'

# setup direnv
eval "$(direnv hook zsh)"

# setup fasd
eval "$(fasd --init auto)"

# auto complete
# export CARAPACE_BRIDGES='fish,bash,inshellisense' # optional
# zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
# source <(carapace _carapace)


# autoload -U compinit
# compinit -i



#####################################
#
# needs to be at the end
eval "$(starship init zsh)"


# bun completions
[ -s "/Users/jorge/.bun/_bun" ] && source "/Users/jorge/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
