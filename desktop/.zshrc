# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Set env variable
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/go/bin:$PATH

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

export GOPATH=$HOME/go

export __GL_SHADER_DISK_CACHE_PATH=$HOME/.config

export TERM="xterm-256color"

# Set oh_my_zsh plugins
plugins=(
    git
    git-extra
    go
    golang
    vagrant
    virtualbox
    docker
    docker-compose
    dotenv
    extract
)

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=15

source $ZSH/oh-my-zsh.sh

eval "$(direnv hook zsh)"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

loop() {
    nb=$1
    shift
    for ((i = 0; i < $nb; i++)); do $@; done
}

alias emacs="vim"
alias vi="vim"
alias open="xdg-open"
