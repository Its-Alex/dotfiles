#If you come from bash you might have to change your $PATH.

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load
ZSH_THEME="spaceship"

# Theme configuration
SPACESHIP_BATTERY_SHOW='always'
SPACESHIP_PROMPT_ADD_NEWLINE=false

# Set env variable
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/go/bin:$PATH

export GOPATH=$HOME/go

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

export __GL_SHADER_DISK_CACHE_PATH=$HOME/.config

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

if [[ -z "$SPACESHIP_VERSION" ]]; then
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
    exec zsh
fi

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

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

alias emacs="vim"
alias vi="vim"
alias open="xdg-open"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
