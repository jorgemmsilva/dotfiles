. "$HOME/.cargo/env"

export PATH="$PATH:/Users/jorges/.foundry/bin"

export PATH="$PATH:/Users/jorges/.foundry/bin"

export PATH="$PATH:/Users/jorge/.foundry/bin"

export PATH="$PATH:/Users/jorge/.sp1/bin"


# RUST
export RUST_LOG="common=debug,shared=debug,synd_batch_sequencer=debug,synd_block_builder=debug,synd_chain_ingestor=debug,synd_maestro=debug,synd_mchain=debug,synd_slotter=debug,synd_tee_attestation_zk_proofs_aws_nitro=debug,synd_tee_attestation_zk_proofs_sp1_script=debug,synd_tee_attestation_zk_proofs_submitter=debug,synd_translator=debug,test_framework=debug,test_utils=debug,info"
export RUST_BACKTRACE=1
export PATH=$PATH:$HOME/.cargo/bin


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
export PATH="$PATH:/Users/jorge/.risc0/bin"

# remove ld warnings
export MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion)
export CGO_LDFLAGS=-Wl,-no_warn_duplicate_libraries

# foundry
export FOUNDRY_DISABLE_NIGHTLY_WARNING=false
