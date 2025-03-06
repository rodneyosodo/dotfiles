# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Download fzf, if it's not installed
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  $HOME/.fzf/install
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::ssh-agent
zinit snippet OMZP::bgnotify
zinit snippet OMZP::dotenv
zinit snippet OMZP::git-prompt
zinit snippet OMZP::virtualenv
zinit snippet OMZP::aliases
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found
zinit snippet OMZP::zsh-interactive-cd
zinit snippet OMZP::zsh-navigation-tools
zinit snippet OMZP::aliases
zinit snippet OMZ::plugins/git/git.plugin.zsh

zinit load 'zsh-users/zsh-history-substring-search'
zinit ice wait atload '_history_substring_search_config'

zinit load atuinsh/atuin

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
# Interactive history search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent identities github
zstyle :omz:plugins:ssh-agent lifetime 30d


# Aliases
alias c='clear'
alias cat='bat'
alias ls='exa --icons=auto -F'
alias ll='exa --icons=auto -F -bgh -l --total-size'
alias fzf='fzf --preview="bat --color=always {}"'

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l -g ""'
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/.cargo/bin
export PATH=$PATH:/opt/google-cloud-cli/bin/
export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin
export GOROOT=/usr/lib/go
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$GOBIN
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Shell integrations
eval $(thefuck --alias)
eval "$(fzf --zsh)"
eval `ssh-agent -s`
eval "$(pyenv init - zsh)"
eval "$(atuin init zsh)"

if [ -f "$HOME/.ssh/github" ]; then
  eval `keychain --quiet --agents ssh --eval $HOME/.ssh/github`
else
  echo "File "~/.ssh/github" does not exist."
fi

if [ ! -d "${HOME}/.npm-packages" ]; then
  mkdir "${HOME}/.npm-packages"
fi
NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$PATH:$NPM_PACKAGES/bin"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

alias makeall="make all -j 8 && make dockers_dev -j 8"
alias gotest="go test -v --race -covermode=atomic -coverprofile=cover.out ./..."
alias gocover="go tool cover -html cover.out -o cover.html"
alias gobenchprof="go test -v -bench=. -benchmem -cpuprofile=cpu.prof -memprofile=mem.prof -coverprofile=prof.out ./..."
alias gpr="git pull --rebase"
alias gprum="git pull --rebase upstream main"
alias gpf="git push --force-with-lease"
alias ze="zellij -l welcome"
alias act="/usr/bin/act"

# Functions

# Function to rebase last n commits and signoff
function rebase_signoff() {
  if [ $# -lt 1 ]; then
    echo "Please provide the number of commits to rebase\nUsage: grs <number-of-commits>"
    return
  fi

  git rebase -i HEAD~$1 --exec "git commit --amend --no-edit --signoff -S"
}

# Function to generate a random password
function genpasswd() {
  local length=$1
  [ -z "$length" ] && length=16
  tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${length} | xargs
}

# Function to clean docker containers
function clean_docker() {
  if [[ $(docker ps -a -q) ]]; then
    docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)
  fi
}
