# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

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
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git ruby postgres rails rake rake-fast rbenv tmux tmuxinator bundler bgnotify macos wd fzf zsh-autosuggestions)

# User configuration

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

export FZF_BASE=/opt/homebrew/bin/fzf
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh
#source ~/.secrets/vars

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
export EDITOR='nvim'

# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# $PATH {{{

is_osx(){
  [ "$(uname -s)" = Darwin ]
}

export PATH=$HOME/bin:/usr/local/bin:$PATH

if is_osx; then
  # Add Homebrew to the path. This must be above rbenv path stuff.
  PATH=/opt/homebrew/bin:$PATH
fi

# Heroku standalone client
PATH="/usr/local/heroku/bin:$PATH"

# Node
PATH=$PATH:/usr/local/share/npm/bin:.git/safe/../../node_modules/.bin/
# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Haskell
PATH=~/.local/bin:$PATH

PATH=$HOME/.bin:$PATH

# The goal here is:
# * ./bin/stubs is before rbenv shims
# * ~/.rbenv/shims is before /usr/local/bin etc
# * I don't know why it has to be in this order but putting shims before stubs
#   breaks stubs ("You have activated the wrong version of rake" error)

eval "$(rbenv init - zsh)"
PATH=./bin/stubs:$PATH

export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# }}}

# By itself: run `git status`
# With arguments: acts like `git`
function g {
  if [[ $# > 0 ]]; then
    git "$@"
  else
    git st
  fi
}

function branchify {
  git checkout -b $1 && git reset master --hard HEAD~
}

# Usage: changes d038ff1 5d7f017
function changes() {
  git log $1..$2 --pretty=format:'*%s*%n%b' --no-merges
}

function git-find-deleted-line {
  git log -c -S $1 $2
}

function git-churn {
  git log --all -M -C --name-only --format='format:' "$@" \
    | sort \
    | grep -v '^$' \
    | uniq -c \
    | sort -n \
    | awk 'BEGIN {print "count\tfile"} {print $1 "\t" $2}'
}

# Homebrew {{{
if is_osx; then
  # Opt out of sending Homebrew information to Google Analytics
  # https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/Analytics.md
  export HOMEBREW_NO_ANALYTICS=1
fi
# }}}

# Alias
source $HOME/.alias
compdef g=git

# Env variables
source $HOME/.env

# Ignore some folders on FZF search
export FZF_DEFAULT_COMMAND='ag --nocolor --ignore tmp --ignore node_modules --ignore spec/vcr_cassettes -g ""'

# zsh-syntax-highlighting must be sourced after all custom widgets have been
# created (i.e., after all zle -N calls and after running compinit), because it
# has to know about them to highlight them.
source ~/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# `print_exit_value` shows a message with the exit code when a command returns
# with a non-zero exit code.
# However, zsh-syntax-highlighting somehow unsets this options option, so we
# must set it after sourcing zsh-syntax-highlighting.
setopt print_exit_value

export PATH="code/gq/infrastructure/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
