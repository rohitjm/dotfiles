# Unlimited history
HISTSIZE=1000000       # in-memory history size
SAVEHIST=1000000       # number of commands saved to file
HISTFILE=~/.zsh_history

# Recommended options
setopt APPEND_HISTORY          # append instead of overwrite
setopt SHARE_HISTORY           # share history across sessions
setopt INC_APPEND_HISTORY      # write after each command
setopt HIST_IGNORE_SPACE       # ignore commands starting with space
setopt HIST_EXPIRE_DUPS_FIRST  # drop older duplicates first

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Add RUST cargo to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# set dotfile directory as env var
export DOTFILE_HOME="$HOME/Dev/dotfiles"
export DOTFILES="$HOME/Dev/dotfiles"

# macOS-only setup (Homebrew, mac-specific app paths)
if [[ "$(uname -s)" == "Darwin" ]]; then
  # Add Homebrew install to PATH
  export PATH="/Users/rmathew/Dev/homebrew/bin:$PATH"

  # Add homebrew ruby installation to PATH
  export PATH="/usr/local/opt/ruby/bin:$PATH"

  # Add gem install directory to PATH
  export PATH="/usr/local/lib/ruby/gems/2.7.0/bin:$PATH"

  # Add Visual Studio Code (code)
  export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

  # Add openJDK to path
  export PATH="/Users/rmathew/Dev/homebrew/opt/openjdk/bin:$PATH"

  # Add GOROOT to PATH
  command -v brew >/dev/null 2>&1 && export GOROOT=$(brew --prefix go)/libexec

  # For compilers to find zlib you may need to set:
  export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
  export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"

  # For pkg-config to find zlib you may need to set:
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
fi

# pyenv (only if installed)
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d $PYENV_ROOT/bin ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - zsh)"
fi

# Add GOROOT/bin and GOPATH/bin to PATH if Go is installed
if command -v go >/dev/null 2>&1; then
  [[ -n "${GOROOT:-}" ]] && export PATH=$GOROOT/bin:$PATH
  export PATH=$PATH:$(go env GOPATH)/bin
fi

#load nvm by default
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load Twilio config (gitignored; only present on the work machine)
[[ -f "$DOTFILE_HOME/untracked/.twilio_zsh" ]] && . "$DOTFILE_HOME/untracked/.twilio_zsh"

# Load Oh-my-ZSH
function loadomz() {
  echo "Loading Oh-my-ZSH..."
  . ~/Dev/dotfiles/zsh/.oh-my-zsh
}

# Load Tmux Aliases
function loadtmux() {
  echo "Loading Tmux aliases..."
  . ~/Dev/dotfiles/zsh/.tmux
}

# Load cross-platform clipboard (pc/pp)
function loadclipboard() {
  . ~/Dev/dotfiles/zsh/.clipboard-helper
}

# Load local AI workstation helpers (claude-local, aiup, aigpu, ...)
function loadai() {
  . ~/Dev/dotfiles/zsh/.ai
}

# For compilers to find zlib you may need to set:
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"

# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"

# general aliases
alias eohmyzsh="nvim ~/.oh-my-zsh"
alias cl="clear";
alias ezsh="nvim $DOTFILE_HOME/zsh/.zshrc";
alias eala="nvim $DOTFILE_HOME/alacritty/alacritty.toml"
alias rzsh="source ~/.zshrc";
alias lsl="ls -lhS";
alias lsla="ls -lahS";
# pc/pp come from .clipboard-helper (loaded below); it picks pbcopy on macOS,
# clip.exe/powershell on WSL, and xclip/wl-copy on native Linux.
alias tojson="python3 -m json.tool"
alias tf="terraform"

# macOS-only aliases
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias showfonts="system_profiler SPFontsDataType"
  alias listjava="/usr/libexec/java_home -V"
fi

# symlinks
alias lnzsh="ln -s -f ~/Dev/dotfiles/zsh/.zshrc ~/.zshrc"



# docker
alias dc="docker-compose"
alias dps="docker ps"
alias drm="docker rm"
alias stopalldocker='docker stop $(docker ps -a -q)'
alias rmalldocker='docker rm $(docker ps -a -q)'

# vscode
alias evscode="nvim $DOTFILE_HOME/vscode/settings.json"

# git
alias gd="git diff";
alias gst="git status";
alias grh="git reset HEAD";
alias gck="git checkout --";
alias gckt="git checkout --track"
alias gcane="git commit --amend --no-edit"
alias gcm='git symbolic-ref --short refs/remotes/origin/HEAD | sed "s|origin/||" | xargs git checkout'
alias glo="git log --oneline"
alias undocommit="git reset --soft HEAD~1";
alias unstage="git restore --staged"

# Kubernetes stuff
alias kb="kubectl"
alias kbx="kubectx"
alias bbox="kubectl run curl-rmathew --image=radial/busyboxplus:curl -i --tty --rm"

setns() {
  if [ -z "$1" ]; then
    echo "Usage: setns <namespace>"
    return 1
  fi
  export KUBE_NAMESPACE="$1"
  alias kb="kubectl -n $KUBE_NAMESPACE"
  echo "✅ Namespace set to '$KUBE_NAMESPACE'"
}

# networking commands
alias sulsof="sudo lsof -i -P | grep "

#Vim commands
alias envim="nvim $DOTFILE_HOME/nvim/init.lua";

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

loadomz
loadtmux
loadclipboard
loadai

