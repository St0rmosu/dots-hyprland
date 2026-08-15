# ==============================================================================
# Oh My Zsh & Plugins Setup
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
ZSH_CUSTOM="$ZSH/custom"

# Install Oh-My-Zsh if it doesn't exist
if [ ! -d "$ZSH" ]; then
  echo "Installing Oh-My-Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH" >/dev/null 2>&1
fi

# Auto-fetch necessary plugins if they don't exist
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >/dev/null 2>&1
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null 2>&1
fi

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"

# ==============================================================================
# History Configuration
# ==============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Alias per eza
alias ls='eza --icons -l --header --color=auto --group-directories-first'
alias l='eza --icons -l --header --color=auto --group-directories-first -a'
alias lt='eza --tree --level=2 --header'
alias proxmox='ssh prox'
alias opencode='opencode --auto'
alias agy='agy --dangerously-skip-permissions'

# ==============================================================================
# Custom Functions
# ==============================================================================

# Automatically list directory contents upon changing directories
cd() {
  builtin cd "$@" && ls
}

# Aggiorna tutti i package manager del sistema
update() {
  echo "==> Aggiornamento sistema (pacman)..."
  
  "$HOME/bin/sudo-pass" pacman -Syu --noconfirm

  echo "==> Aggiornamento AUR con yay..."
  yay -Syu --devel --noconfirm --sudo "$HOME/bin/sudo-pass"

  echo "==> Aggiornamento AUR con paru..."
  paru -Syu --noconfirm --sudo "$HOME/bin/sudo-pass"

  echo "==> Aggiornamento npm globale..."
  npm update -g

  echo "==> Aggiornamento uv..."
  uv tool upgrade --all

  echo "==> Aggiornamento completato!"
}

# use fetch-git (animated 3D fetch)
# config: ~/.config/fetch/config

# ==============================================================================
# Execute on Startup
# ==============================================================================
fetch --infinite


# Added by Antigravity CLI installer
export PATH="/home/lollo/.local/bin:$PATH"
export PATH="/home/lollo/.local/bin:$PATH"

# opencode
export PATH=/home/lollo/.opencode/bin:$PATH

export PATH=$PATH:/home/lollo/.spicetify

# npm global (user prefix)
export PATH="$HOME/.npm-global/bin:$PATH"

# File viewer alias
alias see='tv files | xargs -r nvim'
