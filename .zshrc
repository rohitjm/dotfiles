# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Add go to PATH
export PATH="/usr/local/go/bin:$PATH"

# Add homebrew ruby installation to PATH
export PATH="/usr/local/opt/ruby/bin:$PATH"

# Add gem install directory to PATH
export PATH="/usr/local/lib/ruby/gems/2.7.0/bin:$PATH"

# Add RUST cargo to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH="/Users/rmathew/.oh-my-zsh"

#export PATH="/usr/local/opt/python@2/bin:$PATH"

#load nvm by default
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="af-magic"
#ZSH_THEME="random"
ZSH_THEME="junkfood"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"

# For compilers to find zlib you may need to set:
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"

# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"

alias vim="nvim"
alias eohmyzsh="nvim ~/.oh-my-zsh"
alias cl="clear";
alias ezsh="nvim ~/.zshrc";
alias eala="vim ~/.config/alacritty/alacritty.yml"
alias rzsh="source ~/.zshrc";
alias lsl="ls -lhS";
alias pp="pbpaste"
alias pc="pbcopy"
alias tojson="python -m json.tool"
alias tf="terraform"

alias stopalldocker="docker stop '$(docker ps -a -q)'"
alias rmalldocker="docker rm $(docker ps -a -q)"

# tmux
alias tx="tmux"
alias txa="tmux attach -t"
alias txls="tmux ls"
alias txn="tmux new -s"
alias txsess="~/Dev_Tools/tmux/tmux-session.sh"
alias txk="tmux kill-session -t"

# docker
alias dc="docker-compose"
alias dps="docker ps"
alias drm="docker rm"

# git
alias gd="git diff";
alias gst="git status";
alias grh="git reset HEAD";
alias gck="git checkout --";
alias gcane="git commit --amend --no-edit"
alias gcm="git checkout master"
alias undocommit="git reset --soft HEAD~1";

# Kubernetes stuff
alias kb="kubectl"
alias kbx="kubectx"
alias bbox="kubectl run curl-rmathew --image=radial/busyboxplus:curl -i --tty --rm"

# Set Java version
alias listjava="/usr/libexec/java_home -V"
alias j15="export JAVA_HOME=`/usr/libexec/java_home -v 15.0`; java -version";
alias j11="export JAVA_HOME=`/usr/libexec/java_home -v 11.0`; java -version";
alias j8="export JAVA_HOME=`/usr/libexec/java_home -v 1.8`; java -version";

#networking commands
alias sulsof="sudo lsof -i -P | grep "

#Vim commands
alias evim="vim ~/.vimrc";
alias envim="vim ~/.config/nvim/init.vim";
