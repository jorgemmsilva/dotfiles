. "$HOME/.cargo/env"

# RUST
export RUST_BACKTRACE=1
export PATH=$PATH:$HOME/.cargo/bin

# BUN
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# custom binaries
export PATH=$PATH:$HOME/bin

# GO
export GOPATH=~/go/bin
export GOBIN=$GOPATH
export PATH=$PATH:$GOPATH

# NPM global installs
export PATH=$PATH:$HOME/.local/bin

######## EXTRA #####
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# risc0
export PATH="$PATH:$HOME/.risc0/bin"

# remove ld warnings
export MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion)
export CGO_LDFLAGS=-Wl,-no_warn_duplicate_libraries

# foundry
export FOUNDRY_DISABLE_NIGHTLY_WARNING=false

export PATH="$PATH:$HOME/.foundry/bin"

export PATH="$PATH:$HOME/.sp1/bin"
