#!/bin/bash
set -euo pipefail

# ============================================================
# MacBook Bootstrap — Fresh Mac to fully configured dev machine
# ============================================================
# Run directly ON the new Mac (or SSH in from another machine).
# No keys needed: dotfiles are public, cloned via HTTPS.
# 1Password sign-in is the only manual step.
#
# Usage:
#   bash <(curl -sL https://gist.githubusercontent.com/...)
#   # or just paste and run
# ============================================================

# --- Config ---
DOTFILES_REPO="https://github.com/dluksza/dotfiles.git"
FLAKE_HOST=$(scutil --get LocalHostName) # auto-detect from macOS hostname
CHEZMOI_DIR="$HOME/.local/share/chezmoi"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}▸${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() {
  echo -e "${RED}✗${NC} $1"
  exit 1
}
step() { echo -e "\n${GREEN}━━━ $1 ━━━${NC}\n"; }

# Keep the Mac awake
caffeinate -s -w $$ &

# --- Xcode CLI Tools ---
step "Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
  ok "Already installed"
else
  info "Installing (requires manual approval)..."
  xcode-select --install 2>/dev/null || true
  echo "⏸  Accept the dialog, wait for install to finish."
  until xcode-select -p &>/dev/null; do sleep 5; done
  ok "Installed"
fi

# --- Hostname ---
CURRENT_HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
echo ""
info "Current hostname: ${CURRENT_HOSTNAME}"
read -rp "Enter hostname for this machine [${CURRENT_HOSTNAME}]: " NEW_HOSTNAME
NEW_HOSTNAME="${NEW_HOSTNAME:-$CURRENT_HOSTNAME}"

# Sanitize: only alphanumeric and hyphens allowed for LocalHostName
SANITIZED=$(echo "${NEW_HOSTNAME}" | tr -cd 'a-zA-Z0-9-' | sed 's/^-//;s/-$//')
if [[ "${SANITIZED}" != "${NEW_HOSTNAME}" ]]; then
  warn "Hostname sanitized: '${NEW_HOSTNAME}' → '${SANITIZED}'"
  NEW_HOSTNAME="${SANITIZED}"
fi

if [[ -z "${NEW_HOSTNAME}" ]]; then
  fail "Hostname cannot be empty"
fi

if [[ "${NEW_HOSTNAME}" != "${CURRENT_HOSTNAME}" ]]; then
  info "Setting hostname to '${NEW_HOSTNAME}'..."
  sudo scutil --set ComputerName "${NEW_HOSTNAME}"
  sudo scutil --set LocalHostName "${NEW_HOSTNAME}"
  sudo scutil --set HostName "${NEW_HOSTNAME}.local"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${NEW_HOSTNAME}"
  ok "Hostname set to ${NEW_HOSTNAME}"
else
  ok "Keeping hostname: ${NEW_HOSTNAME}"
fi

FLAKE_HOST="${NEW_HOSTNAME}"

# --- Install Nix ---
step "Nix"

if command -v nix &>/dev/null; then
  ok "Already installed: $(nix --version)"
else
  info "Installing Determinate Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix | sh -s -- install --no-confirm
  ok "Nix installed"
fi

# Source nix for this session
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true

# --- Clone dotfiles ---
step "Dotfiles"

if [[ -d "${CHEZMOI_DIR}/.git" ]]; then
  ok "Already cloned, pulling latest..."
  cd "${CHEZMOI_DIR}" && git pull
else
  info "Cloning from GitHub (HTTPS, no auth needed)..."
  git clone "${DOTFILES_REPO}" "${CHEZMOI_DIR}"
  ok "Cloned to ${CHEZMOI_DIR}"
fi

# --- Rename conflicting /etc files ---
step "Preparing /etc for nix-darwin"

for f in /etc/zshenv /etc/zshrc /etc/bashrc; do
  if [ -f "$f" ] && [ ! -f "${f}.before-nix-darwin" ]; then
    sudo mv "$f" "${f}.before-nix-darwin"
    info "Renamed $f"
  fi
done
ok "Done"

# --- Build nix-darwin ---
step "nix-darwin"

info "Building system configuration (this takes a while on first run)..."

# First run: read flake from chezmoi source dir (dot_ prefix)
# After chezmoi apply, it lives at ~/.config/nix-darwin/
BOOTSTRAP_FLAKE_DIR="${CHEZMOI_DIR}/dot_config/nix-darwin"
FINAL_FLAKE_DIR="$HOME/.config/nix-darwin"

if [[ ! -d "${BOOTSTRAP_FLAKE_DIR}" ]]; then
  fail "Flake not found at ${BOOTSTRAP_FLAKE_DIR}. Check chezmoi repo structure."
fi

if ! command -v darwin-rebuild &>/dev/null; then
  info "First-time nix-darwin install (reading from chezmoi source)..."
  sudo nix run nix-darwin -- switch --flake "${BOOTSTRAP_FLAKE_DIR}#${FLAKE_HOST}"
else
  sudo darwin-rebuild switch --flake "${BOOTSTRAP_FLAKE_DIR}#${FLAKE_HOST}"
fi
ok "System built and activated (1Password, chezmoi, packages installed)"

# Refresh PATH: non-interactive bash won't source /etc/bashrc automatically,
# so nix-darwin's PATH (including /run/current-system/sw/bin) isn't available yet.
if [[ -e /etc/static/bashrc ]]; then
  source /etc/static/bashrc
fi

# --- 1Password sign-in (manual) ---
step "1Password Setup"

echo "┌─────────────────────────────────────────────────┐"
echo "│  Open 1Password and sign in.                    │"
echo "│  Then: Settings → Developer → SSH Agent → On    │"
echo "│                                                 │"
echo "│  chezmoi needs 'op' to decrypt secrets.         │"
echo "└─────────────────────────────────────────────────┘"
read -rp "Press Enter when 1Password is signed in and SSH agent is enabled... " _

# Verify op works
if op account list &>/dev/null; then
  ok "1Password CLI connected"
else
  warn "op CLI not authenticated. chezmoi may fail on encrypted files."
  warn "Run 'eval \$(op signin)' if needed, then re-run 'chezmoi apply'."
fi

# --- Apply chezmoi dotfiles ---
step "chezmoi"

if command -v chezmoi &>/dev/null; then
  chezmoi apply
  ok "Dotfiles applied"
else
  fail "chezmoi not found after nix-darwin build. Is it in your nix config?"
fi

# --- Switch git remote to SSH (for pushes) ---
step "Git remote"

cd "${CHEZMOI_DIR}"
git remote set-url origin git@github.com:dluksza/dotfiles.git
ok "Remote switched to SSH (pushes use 1Password agent)"

# --- Remove Apple bloatware ---
step "Cleanup"

sudo rm -rf /Applications/GarageBand.app /Applications/iMovie.app \
  /Applications/Keynote.app /Applications/Numbers.app \
  /Applications/Pages.app 2>/dev/null || true
ok "Bloatware removed"

# --- Verify ---
step "Verification"

echo "--- System ---"
uname -a
echo ""
echo "--- Nix ---"
nix --version
echo ""
echo "--- Git SSH ---"
ssh -T git@github.com 2>&1 || true
echo ""

step "Bootstrap complete! 🎉"

cat <<DONE
Your MacBook is ready.

Rebuild after config changes:
  darwin-rebuild switch --flake ~/.config/nix-darwin#${FLAKE_HOST}

Update dotfiles:
  chezmoi update
DONE
