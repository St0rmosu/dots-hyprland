#!/usr/bin/env bash
# ==============================================================================
#  🚀 St0rmosu Hyprland & Custom Applications Auto-Installer
#  Autore: Lorenzo Recchia (St0rmosu)
#  Ambiente: Arch Linux (pacman, paru / yay)
# ==============================================================================

set -e

# Colori per il terminale
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🚀 Installatore Personalizzato App & Ambiente Hyprland     ║${NC}"
echo -e "${CYAN}║                    by Lorenzo Recchia                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Verifica utente non root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}❌ Non eseguire questo script come root/sudo. Verranno richiesti i privilegi quando necessario.${NC}"
  exit 1
fi

# 2. Controllo e installazione AUR Helpers (yay e paru)
echo -e "${BLUE}==>${NC} Controllo AUR Helpers (yay & paru)..."
sudo pacman -S --needed --noconfirm base-devel git curl wget

if ! command -v yay &> /dev/null; then
  echo -e "${YELLOW}==> Installazione yay...${NC}"
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
  rm -rf /tmp/yay-bin
fi

if ! command -v paru &> /dev/null; then
  echo -e "${YELLOW}==> Installazione paru...${NC}"
  git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
  (cd /tmp/paru-bin && makepkg -si --noconfirm)
  rm -rf /tmp/paru-bin
fi

AUR="paru"
echo -e "${GREEN}✓ AUR Helpers pronti: yay & paru${NC}\n"

# 3. Pacchetti Ufficiali Arch (pacman)
PACMAN_APPS=(
  # Terminale & Shell
  foot
  zsh
  starship
  fastfetch
  eza
  bat
  ripgrep
  fd
  fzf
  btop
  television
  
  # File manager & Utility
  nautilus
  nautilus-open-any-terminal
  git
  github-cli
  unzip
  p7zip
  jq
  bc
  
  # Screenshot & Media
  satty
  grim
  slurp
  swappy
  wl-clipboard
  cliphist
  brightnessctl
  playerctl
  pavucontrol-qt
  
  # Editor
  neovim
)

# 4. Pacchetti AUR (paru/yay)
AUR_APPS=(
  yayfzf
  fetch-git
  zen-browser-bin
  vscodium-bin
  whatsapp-linux-desktop-bin
  spotify
  spicetify-cli
  localsend-bin
  proton-vpn-gtk-app
  quickshell-git
  matugen-bin
  ttf-jetbrains-mono-nerd
  noto-fonts-emoji
  bibata-cursor-theme
)

# 5. Installazione Pacchetti
echo -e "${BLUE}==>${NC} [1/5] Aggiornamento dei repository di sistema..."
sudo pacman -Syu --noconfirm

echo -e "\n${BLUE}==>${NC} [2/5] Installazione Applicazioni da Arch Repository (pacman)..."
sudo pacman -S --needed --noconfirm "${PACMAN_APPS[@]}"

echo -e "\n${BLUE}==>${NC} [3/5] Installazione Applicazioni da AUR (paru)..."
$AUR -S --needed --noconfirm "${AUR_APPS[@]}"

# 6. Configurazione ZSH & Oh My Zsh
echo -e "\n${BLUE}==>${NC} [4/5] Configurazione Shell ZSH & Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo -e "  -> Installazione Oh My Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" >/dev/null 2>&1
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo -e "  -> Plugin zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >/dev/null 2>&1
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo -e "  -> Plugin zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null 2>&1
fi

# Copia .zshrc se presente nella cartella dots
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/dots/.zshrc" ]; then
  echo -e "  -> Applicazione configurazione .zshrc..."
  cp "$SCRIPT_DIR/dots/.zshrc" "$HOME/.zshrc"
fi

# Imposta zsh come shell predefinita se non lo è già
if [ "$SHELL" != "$(which zsh)" ]; then
  echo -e "  -> Impostazione ZSH come shell di default..."
  chsh -s "$(which zsh)" "$USER" || true
fi

# 7. Configurazione Neovim (LazyVim) & Dev Tools (OpenCode / Antigravity)
echo -e "\n${BLUE}==>${NC} [5/5] Configurazione LazyVim, OpenCode & Tool Dev..."

# LazyVim
if [ ! -d "$HOME/.config/nvim" ] || [ ! -f "$HOME/.config/nvim/lua/config/lazy.lua" ]; then
  echo -e "  -> Installazione starter LazyVim per Neovim..."
  rm -rf "$HOME/.config/nvim.bak" 2>/dev/null || true
  [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" >/dev/null 2>&1
  rm -rf "$HOME/.config/nvim/.git"
fi

# OpenCode
if ! command -v opencode &> /dev/null && [ ! -f "$HOME/.opencode/bin/opencode" ]; then
  echo -e "  -> Installazione OpenCode CLI..."
  curl -fsSL https://opencode.ai/install | bash 2>/dev/null || true
fi

# Antigravity CLI
if ! command -v agy &> /dev/null && [ ! -f "$HOME/.local/bin/agy" ]; then
  echo -e "  -> Verifica Antigravity CLI..."
  curl -fsSL https://antigravity.google/install.sh | bash 2>/dev/null || true
fi

echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Installazione completata con successo!${NC}"
echo -e "${GREEN}  - Terminale: foot${NC}"
echo -e "${GREEN}  - Shell: zsh (con Oh My Zsh, autosuggestions e syntax highlighting)${NC}"
echo -e "${GREEN}  - File Manager: nautilus${NC}"
echo -e "${GREEN}  - Editor: neovim (LazyVim) & vscodium${NC}"
echo -e "${GREEN}  - Browser: zen-browser${NC}"
echo -e "${GREEN}  - Tool: yay, paru, yayfzf, television (tv), fastfetch, fetch-git, btop${NC}"
echo -e "${GREEN}  - App: whatsapp, spotify, localsend, proton-vpn, quickshell focustime${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}\n"
