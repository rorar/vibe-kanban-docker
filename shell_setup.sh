#!/bin/bash
# Shell configuration for vibe-kanban-docker
# Provides aliases, completions, and convenience functions

# ============================================================================
# Aliases
# ============================================================================

# Modern ls alternatives
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --level=2 --icons --git'
alias l='eza -la --icons --git'

# Git aliases with delta for pretty diffs
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Enable delta for git diff
export DELTA_PAGER="less -R"
git config --global core.pager delta
git config --global delta.navigate true
git config --global delta.side-by-side true

# Pretty git log
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# General aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Process monitoring
alias psmem='ps aux --sort=-%mem | head -10'

# ============================================================================
# FZF Configuration
# ============================================================================

# Add fzf keybindings if available
if command -v fzf &> /dev/null; then
    # Ctrl+R: search command history
    # Ctrl+T: search files
    # Alt+C: cd into directories
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_CTRL_R_OPTS='--height 40% --layout=reverse --border'
    export FZF_ALT_C_OPTS='--height 40% --layout=reverse --border'
    
    # Use eza for file previews in fzf
    export FZF_CTRL_T_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
fi

# ============================================================================
# Shell Completions
# ============================================================================

# Enable bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Enable git completion
if [ -f /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
fi

# ============================================================================
# Convenience Functions
# ============================================================================

# Quick extract
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Make and cd into directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and open in editor
fe() {
    local file
    file=$(fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null') && $EDITOR "$file"
}

# ============================================================================
# Environment
# ============================================================================

# Set editor
export EDITOR="${EDITOR:-nano}"
export VISUAL="${EDITOR:-nano}"

# Enable True Color (24-bit) support for modern terminal apps
export TERM=xterm-truecolor

# Colors for less
export LESS='-R'
export LESS_TERMCAP_mb=$'\033[1;31m'
export LESS_TERMCAP_md=$'\033[1;36m'
export LESS_TERMCAP_me=$'\033[0m'
export LESS_TERMCAP_se=$'\033[0m'
export LESS_TERMCAP_so=$'\033[1;44;33m'
export LESS_TERMCAP_ue=$'\033[0m'
export LESS_TERMCAP_us=$'\033[1;32m'

# ============================================================================
# The Fuck (Command Correction)
# ============================================================================
if command -v thefuck &> /dev/null; then
    eval $(thefuck --alias)
    eval $(thefuck --alias FUCK)
fi
