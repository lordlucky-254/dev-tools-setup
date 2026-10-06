#!/usr/bin/env bash
# dev-tools-setup — cross-platform developer tool installer (Linux / macOS)
# Idempotent: safe to re-run.
set -uo pipefail

bold=$'\e[1m'; green=$'\e[32m'; yellow=$'\e[33m'; red=$'\e[31m'; reset=$'\e[0m'
info()  { echo "${bold}==> ${reset}$*"; }
ok()    { echo "${green}    $*${reset}"; }
warn()  { echo "${yellow}    ! $*${reset}"; }
fail()  { echo "${red}    x $*${reset}"; }

DNF_PKGS=(git curl wget zsh tmux ripgrep fd-find fzf jq gh tree htop unzip
          gcc gcc-c++ make cmake gdb neovim openjdk-21-devel golang python3)
APT_PKGS=(git curl wget zsh tmux ripgrep fd-find fzf jq gh tree htop unzip
          build-essential cmake gdb neovim openjdk-21-jdk golang-go python3)
PACMAN_PKGS=(git curl wget zsh tmux ripgrep fd fzf jq github-cli tree htop unzip
             base-devel cmake gdb neovim jdk-openjdk go python)
ZYPPER_PKGS=(git curl wget zsh tmux ripgrep fd fzf jq gh tree htop unzip
             gcc gcc-c++ make cmake gdb neovim java-21-openjdk-devel go python3)
BREW_PKGS=(git curl zsh tmux ripgrep fd fzf jq gh tree htop neovim go python
           cmake wget)

os="$(uname -s)"
[ "$os" = "Darwin" ] && os="macos"

# ---------- OS package manager ----------
install_system_pkgs() {
  local pkgs=()
  if [ "$os" = "macos" ]; then
    if ! command -v brew >/dev/null 2>&1; then
      info "Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { fail "Homebrew install failed"; exit 1; }
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
    fi
    ok "Using Homebrew"
    pkgs=("${BREW_PKGS[@]}")
    for p in "${pkgs[@]}"; do brew list "$p" >/dev/null 2>&1 || brew install "$p" || warn "skipped $p"; done
    return
  fi

  local pm=""
  if   command -v dnf     >/dev/null 2>&1; then pm=dnf;     pkgs=("${DNF_PKGS[@]}")
  elif command -v apt-get >/dev/null 2>&1; then pm=apt;     pkgs=("${APT_PKGS[@]}")
  elif command -v pacman  >/dev/null 2>&1; then pm=pacman;  pkgs=("${PACMAN_PKGS[@]}")
  elif command -v zypper  >/dev/null 2>&1; then pm=zypper;  pkgs=("${ZYPPER_PKGS[@]}")
  else fail "No supported package manager found (dnf/apt/pacman/zypper)"; exit 1
  fi
  info "Installing system packages via $pm"

  # Install one at a time so a missing/renamed package skips cleanly.
  local ok_count=0 skip_count=0
  for p in "${pkgs[@]}"; do
    case "$pm" in
      dnf)     sudo dnf install -y "$p" >/dev/null 2>&1 && ok_count=$((ok_count+1)) || { warn "skipped $p"; skip_count=$((skip_count+1)); } ;;
      apt)     sudo apt-get install -y "$p" >/dev/null 2>&1 && ok_count=$((ok_count+1)) || { warn "skipped $p"; skip_count=$((skip_count+1)); } ;;
      pacman)  sudo pacman -S --noconfirm --needed "$p" >/dev/null 2>&1 && ok_count=$((ok_count+1)) || { warn "skipped $p"; skip_count=$((skip_count+1)); } ;;
      zypper)  sudo zypper --non-interactive install "$p" >/dev/null 2>&1 && ok_count=$((ok_count+1)) || { warn "skipped $p"; skip_count=$((skip_count+1)); } ;;
    esac
  done
  ok "$ok_count installed, $skip_count skipped"
}

# ---------- language toolchains ----------
install_nvm_node() {
  info "Node.js (nvm + LTS)"
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm install --lts >/dev/null 2>&1 && nvm use --lts >/dev/null 2>&1
  else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash >/dev/null 2>&1
    . "$NVM_DIR/nvm.sh"
    nvm install --lts >/dev/null 2>&1 && nvm use --lts >/dev/null 2>&1
  fi
  command -v node >/dev/null 2>&1 && ok "node $(node -v)" || warn "node install failed"
}

install_uv_python() {
  info "Python (uv)"
  if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
    export PATH="$HOME/.local/bin:$PATH"
  fi
  command -v uv >/dev/null 2>&1 && ok "uv $(uv --version | awk '{print $2}')" || warn "uv install failed"
}

install_rust() {
  info "Rust (rustup)"
  if ! command -v rustc >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null 2>&1
    . "$HOME/.cargo/env" 2>/dev/null
  fi
  command -v rustc >/dev/null 2>&1 && ok "rustc $(rustc --version | awk '{print $2}')" || warn "rust install failed"
}

# ---------- editors & platforms ----------
install_docker() {
  info "Docker"
  if command -v docker >/dev/null 2>&1; then
    ok "docker $(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    return
  fi
  if [ "$os" = "macos" ]; then
    warn "Install Docker Desktop from https://docker.com/products/docker-desktop"
  else
    curl -fsSL https://get.docker.com | sudo sh >/dev/null 2>&1 || warn "docker install failed"
    sudo usermod -aG docker "$USER" 2>/dev/null && warn "log out/in for docker group to apply"
    command -v docker >/dev/null 2>&1 && ok "docker installed" || warn "docker install failed"
  fi
}

install_vscode() {
  info "VS Code"
  if command -v code >/dev/null 2>&1; then ok "already installed"; return; fi
  case "$os" in
    macos) brew list --cask visual-studio-code >/dev/null 2>&1 || brew install --cask visual-studio-code || warn "skipped" ;;
    linux)
      if   command -v dnf    >/dev/null 2>&1; then sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc >/dev/null 2>&1; sudo dnf config-manager --add-repo https://packages.microsoft.com/yum/repos/vscode.repo >/dev/null 2>&1; sudo dnf install -y code || warn "skipped"
      elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --noconfirm --needed code || warn "skipped"
      elif command -v apt-get >/dev/null 2>&1; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/ms.gpg >/dev/null 2>&1
        echo "deb [signed-by=/usr/share/keyrings/ms.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        sudo apt-get update -qq && sudo apt-get install -y code || warn "skipped"
      fi ;;
  esac
  command -v code >/dev/null 2>&1 && ok "vscode installed" || true
}

install_starship() {
  info "starship prompt"
  command -v starship >/dev/null 2>&1 || curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1
  command -v starship >/dev/null 2>&1 && ok "starship installed" || warn "starship failed"
}

install_opencode() {
  info "opencode"
  command -v opencode >/dev/null 2>&1 || curl -fsSL https://opencode.ai/install | bash >/dev/null 2>&1
  command -v opencode >/dev/null 2>&1 && ok "opencode installed" || warn "opencode failed"
}

install_gh_login() {
  info "GitHub CLI"
  if command -v gh >/dev/null 2>&1; then
    gh auth status >/dev/null 2>&1 && ok "already authenticated" || warn "run: gh auth login"
  fi
}

# ---------- run ----------
install_system_pkgs
install_nvm_node
install_uv_python
install_rust
install_docker
install_vscode
install_starship
install_opencode
install_gh_login

echo
bold_c=$'\e[1m'; reset_c=$'\e[0m'
echo "${bold_c}Done!${reset_c} Next steps:"
echo "  1. Restart your shell (or re-login for docker group)"
echo "  2. nvim            -> bootstraps plugins/LSP on first run"
echo "  3. gh auth login   -> authenticate GitHub CLI"
echo "  4. opencode        -> AI assistant ready"
