# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Add Homebrew install to PATH
export PATH="/Users/rmathew/Dev/homebrew/bin:$PATH"

# Add go to PATH
export PATH="/usr/local/go/bin:$PATH"

# Add homebrew ruby installation to PATH
export PATH="/usr/local/opt/ruby/bin:$PATH"

# Add gem install directory to PATH
export PATH="/usr/local/lib/ruby/gems/2.7.0/bin:$PATH"

# Add RUST cargo to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# set dotfile directory as env var
export DOTFILE_HOME="~/Dev/dotfiles/"

# Add Visual Studio Code (code)
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# pyenv
# Set the location for pyenv
export PYENV_ROOT="$HOME/.pyenv"

# Add pyenv to the PATH if its directory exists
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv for Zsh
eval "$(pyenv init - zsh)"

# Add openJDK to path
export PATH="/Users/rmathew/Dev/homebrew/opt/openjdk/bin:$PATH"

export DOTFILES="$HOME/Dev/dotfiles"

#load nvm by default
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load Twilio config
. ~/Dev/dotfiles/untracked/.twilio_zsh

# Load Oh-my-ZSH
function loadomz() {
  echo "Loading Oh-my-ZSH..."
  . ~/Dev/dotfiles/zsh/.oh-my-zsh
}

# For compilers to find zlib you may need to set:
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"

# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"

# general aliases
alias vim="nvim"
alias eohmyzsh="nvim ~/.oh-my-zsh"
alias cl="clear";
alias ezsh="nvim $DOTFILE_HOME/zsh/.zshrc";
alias eala="nvim $DOTFILE_HOME/alacritty/alacritty.yml"
alias rzsh="source ~/.zshrc";
alias lsl="ls -lhS";
alias lsla="ls -lahS";
alias pp="pbpaste"
alias pc="pbcopy"
alias tojson="python -m json.tool"
alias tf="terraform"
alias showfonts="system_profiler SPFontsDataType"

# symlinks
alias lnzsh="ln -s -f ~/Dev/dotfiles/zsh/.zshrc ~/.zshrc"

# tmux
alias txsess="$DOTFILE_HOME/tmux/tmux-session.sh"
alias tx="tmux"
alias txa="tmux attach -t"
alias txls="tmux ls"
alias txn="tmux new -s"
alias txk="tmux kill-session -t"

# docker
alias dc="docker-compose"
alias dps="docker ps"
alias drm="docker rm"
alias stopalldocker="docker stop '$(docker ps -a -q)'"
alias rmalldocker="docker rm $(docker ps -a -q)"

# vscode
alias evscode="nvim $DOTFILE_HOME/vscode/settings.json"

# git
alias gd="git diff";
alias gst="git status";
alias grh="git reset HEAD";
alias gck="git checkout --";
alias gckt="git checkout --track"
alias gcane="git commit --amend --no-edit"
alias gcm="git checkout master"
alias glo="git log --oneline"
alias undocommit="git reset --soft HEAD~1";

# Kubernetes stuff
alias kb="kubectl"
alias kbx="kubectx"
alias bbox="kubectl run curl-rmathew --image=radial/busyboxplus:curl -i --tty --rm"

# Set Java version
alias listjava="/usr/libexec/java_home -V"

# networking commands
alias sulsof="sudo lsof -i -P | grep "

#Vim commands
alias envim="vim $DOTFILE_HOME/nvim/init.vim";
eval "$(pyenv init -)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

. "$HOME/.local/bin/env"
