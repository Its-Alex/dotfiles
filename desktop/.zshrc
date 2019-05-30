#!/bin/bash

# Environment variable
#  Path
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
#  Android
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH
export ANDROID_HOME=$HOME/Android/Sdk
#  Golang
export GOPATH=$HOME/go
#  Gpg
GPG_TTY=$(tty)
export GPG_TTY
#  Opengl
export __GL_SHADER_DISK_CACHE_PATH=$HOME/.config
#  Brew
if [[ $(uname) == "Darwin" ]]; then
    export HOMEBREW_INSTALL_CLEANUP=1
fi

# Oh my zsh
#  Path to your oh_my_zsh installation.
export ZSH=$HOME/.oh-my-zsh
#  shellcheck disable=SC2034 # Set name of the oh_my_zsh theme to load
ZSH_THEME="robbyrussell"
#  shellcheck disable=SC2034 # Set oh_my_zsh plugins
plugins=(
    git
    git-extras
    vagrant
    docker
    docker-compose
    extract
)
#  Set update all 15 days
export UPDATE_ZSH_DAYS=15
#  shellcheck source=/dev/null # Load oh_my_zsh
source "${ZSH}/oh-my-zsh.sh"

# Zgen
#  shellcheck source=/dev/null # Load zgen
source "${HOME}/.zgen/zgen.zsh"

# Hooks
#  Direnv
if [ -x "$(command -v direnv)" ]; then
    eval "$(direnv hook zsh)"
fi
#  Pipenv
if [ -x "$(command -v pipenv)" ]; then
    eval "$(pipenv --completion)"
fi

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Ssh
export SSH_KEY_PATH="$HOME/.ssh/itsalex"
if [[ $(uname) != "Darwin" ]]; then
#  if [ ! -S ~/.ssh/ssh_auth_sock ]; then
#    eval $(ssh-agent) &> /dev/null
#    ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
#  fi
#  export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
    if [ -n "$DESKTOP_SESSION" ];then
        eval $(gnome-keyring-daemon --start)
        export SSH_AUTH_SOCK
    fi
fi

# Alias
alias emacs="vim"
alias vi="vim"
if [[ $(uname) == "Darwin" ]]; then
    alias code="open -a \"Visual Studio Code - Insiders\""
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
