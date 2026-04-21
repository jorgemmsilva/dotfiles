# dotfiles

my dotfiles for ease of portability

## Install

https://ohmyz.sh/

few plugins that have to be manually installed:
```
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
```


https://github.com/starship/starship

tmux
tpm: 
```shell
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

https://github.com/delta-io/delta

https://sw.kovidgoyal.net/kitty/

https://github.com/ajeetdsouza/zoxide

https://github.com/junegunn/fzf

https://neovim.io/


```shell
cargo install tree-sitter-cli
```
