# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Set env variable
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

export GOPATH=$HOME/go

export __GL_SHADER_DISK_CACHE_PATH=$HOME/.config

export DOCKER_DEDIBOX_CI_USER=dedibox-ci-cd

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
    extract
)

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=15

source $ZSH/oh-my-zsh.sh

# Direnv hook
eval "$(direnv hook zsh)"
# Pipenv hook
eval "$(pipenv --completion)"

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
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

alias emacs="vim"
alias vi="vim"
alias code="open -a \"Visual Studio Code\""

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/vault vault

# added by travis gem
[ -f /Users/itsalex/.travis/travis.sh ] && source /Users/itsalex/.travis/travis.sh
