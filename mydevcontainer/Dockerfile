FROM fedora:latest

# ── System packages ──────────────────────────────────────────────
# These change rarely — good cache layer
RUN dnf install -y \
    @development-tools git curl wget unzip ripgrep fd-find \
    rustup golang \
    jq \
    git-delta openssh gnupg2 \
    gcc gcc-c++ clang clang-devel \
    fuse-libs \
    zsh fzf lsd zoxide direnv \
    && dnf clean all

# ── Neovim 0.12 (nightly, not yet in Fedora repos) ──────────────
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/v0.12.0/nvim-linux-arm64.tar.gz \
    | tar xz -C /usr/local --strip-components=1

# ── Rust toolchain + cargo tools (slow, cached early) ───────────
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="/usr/local/cargo/bin:${PATH}"
RUN rustup-init -y --no-modify-path --default-toolchain stable \
    && rustup component add rust-analyzer \
    && rustup toolchain install nightly \
    && rustup component add rustfmt --toolchain nightly

# Cargo installs — separate layer so rustup changes don't retrigger
RUN cargo install tree-sitter-cli stylua taplo-cli

# ── Non-root user ────────────────────────────────────────────────
ARG UID=501
RUN useradd -m -u ${UID} -s /bin/zsh dev

RUN mkdir -p /home/dev/.local/share/nvim \
    /home/dev/.vim/undodir \
    /home/dev/.cache/nvim \
    /workspace \
    && chown -R dev:dev /home/dev /workspace

USER dev
WORKDIR /home/dev

# ── Bun ──────────────────────────────────────────────────────────
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/home/dev/.bun"
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

# ── Foundry (forge, cast, anvil, chisel) ─────────────────────────
RUN curl -fsSL https://foundry.paradigm.xyz | bash \
    && /home/dev/.foundry/bin/foundryup
ENV PATH="/home/dev/.foundry/bin:${PATH}"

# ── Go env ───────────────────────────────────────────────────────
ENV GOPATH="/home/dev/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# ── Claude Code ──────────────────────────────────────────────────
RUN curl -fsSL https://claude.ai/install.sh | bash

# ── Starship prompt ──────────────────────────────────────────────
RUN mkdir -p /home/dev/.local/bin \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /home/dev/.local/bin
ENV PATH="/home/dev/.local/bin:${PATH}"
COPY --chown=dev:dev starship.toml /home/dev/.config/starship.toml
RUN echo 'eval "$(starship init bash)"' >> /home/dev/.bashrc

# ── Neovim config (changes often — late layer) ──────────────────
COPY --chown=dev:dev nvim-config /home/dev/.config/nvim

# ── Pre-install plugins ─────────────────────────────────────────
RUN nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true

# ── Pre-install treesitter parsers ───────────────────────────────
RUN nvim --headless \
    -c "lua require('nvim-treesitter').install({'lua','luadoc','printf','vim','vimdoc','nu','typescript','rust','go','toml','json','html','css','javascript','markdown','bash','solidity'})" \
    -c "sleep 30" -c "qa!" 2>&1 | tail -5 || true

# ── Mason: pre-install LSP servers ──────────────────────────────
RUN nvim --headless \
    -c "MasonInstall lua-language-server rust-analyzer gopls typescript-language-server nomicfoundation-solidity-language-server solhint" \
    -c "sleep 60" -c "qa!" 2>&1 | tail -5 || true

WORKDIR /workspace

ENV TERM=xterm-256color
ENV COLORTERM=truecolor
ENV SHELL=/bin/zsh

ENTRYPOINT ["nvim"]
