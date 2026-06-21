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
CHEZMOI_DIR="$HOME/.local/share/chezmoi"
# Machine profile: selects the flake attr (.#personal / .#work) AND the
# chezmoi data profile. NOT the hostname. Override non-interactively with:
#   PROFILE=work bash <(curl -sL .../bootstrap.sh)
PROFILE="${PROFILE:-}"

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

# --- Preflight: can this Mac actually run Determinate Nix + nix-darwin? ---
# Only the admin/sudo gate is deterministic; APFS and MDM are heuristics.
# On a managed/locked-down company laptop these are the usual blockers.
nix_fallback() {
  echo -e "\n${RED}✗ Determinate Nix + nix-darwin is not viable on this Mac.${NC}"
  echo -e "${YELLOW}Reason:${NC} $1\n"
  cat <<FALLBACK
Use the Homebrew + manual fallback. chezmoi dotfiles still work; only the
nix-darwin system layer (macOS defaults, firewall, sshd hardening) is skipped.

  1. Install Homebrew:
     /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  2. Install chezmoi + 1Password (for the age key), then apply this profile:
     brew install chezmoi
     brew install --cask 1password 1password-cli
     CHEZMOI_PROFILE=${PROFILE:-work} chezmoi init --apply dluksza

  3. Install the dev stack by hand — the lists live in the flake:
       dot_config/nix-darwin/modules/{common,flutter}.nix
     e.g. brew install fvm fastlane cocoapods openjdk@17 pre-commit
          brew install --cask android-studio google-chrome \\
                              visual-studio-code android-platform-tools
FALLBACK
  exit 1
}

preflight() {
  step "Preflight"

  # Already installed on a prior run -> we are past these gates.
  if command -v nix &>/dev/null; then
    ok "Nix already present — skipping preflight"
    return
  fi

  # 1. Local admin (deterministic): the installer and darwin-rebuild need sudo.
  if id -Gn 2>/dev/null | tr ' ' '\n' | grep -qx admin; then
    ok "User '$(whoami)' is a local admin"
  else
    nix_fallback "your account is not a local administrator, so 'sudo' (required by the Nix installer and darwin-rebuild) is unavailable."
  fi

  # 2. sudo actually usable (MDM can restrict it even for admins).
  info "Validating sudo (you may be prompted for your password)..."
  if sudo -v; then
    ok "sudo works"
  else
    nix_fallback "'sudo' could not be validated — it appears restricted on this machine."
  fi

  # 3. Root volume is APFS — Determinate creates an APFS volume for /nix.
  if diskutil info / 2>/dev/null | grep -qiE "type \(bundle\):[[:space:]]+apfs"; then
    ok "Root volume is APFS"
  else
    warn "Could not confirm the root volume is APFS — Determinate Nix requires it."
    read -rp "Continue anyway? [y/N]: " _apfs || true
    [[ "${_apfs:-}" =~ ^[Yy] ]] || nix_fallback "root volume does not appear to be APFS."
  fi

  # 4. MDM enrollment (heuristic): strict policies can block the /nix volume,
  #    the installer binary, or network access to the Nix cache (proxy/DLP).
  if profiles status -type enrollment 2>/dev/null | grep -qiE "mdm enrollment:[[:space:]]*yes"; then
    warn "This Mac is enrolled in MDM. Light MDM is usually fine, but strict policies can block /nix volume creation, the installer, or the Nix binary cache."
    if [[ "${ASSUME_MDM_OK:-}" != "1" ]]; then
      read -rp "Proceed with Determinate Nix anyway? [y/N]: " _mdm || true
      [[ "${_mdm:-}" =~ ^[Yy] ]] || nix_fallback "MDM-managed and you chose not to proceed. If a later step fails on volume/network, use the fallback above."
    fi
    ok "Proceeding despite MDM (per your confirmation)"
  else
    ok "No MDM enrollment detected"
  fi
}

preflight

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

# --- Profile ---
step "Profile"
# The flake attribute name is a selector, independent of the hostname above.
if [[ -z "${PROFILE}" ]]; then
  echo "Which profile is this machine?"
  echo "  1) personal  — full setup (personal apps + dev stack)"
  echo "  2) work      — Flutter dev stack only, no personal apps/secrets"
  read -rp "Select [1/2]: " _pchoice
  case "${_pchoice}" in
    2) PROFILE="work" ;;
    *) PROFILE="personal" ;;
  esac
fi
if [[ "${PROFILE}" != "personal" && "${PROFILE}" != "work" ]]; then
  fail "Invalid PROFILE '${PROFILE}' (expected 'personal' or 'work')"
fi
ok "Profile: ${PROFILE}"

# --- Account identity (user + uid baked into the nix-darwin host file) ---
# Nix evaluates the flake purely and cannot run `id -u` itself, so the login
# account lives in hosts/<profile>.nix (`_module.args.user/uid`). Surface the
# real values here and refuse to build while the work host still has the
# placeholder — otherwise nix-darwin would manage the wrong account.
step "Account identity"
DETECTED_USER="$(whoami)"
DETECTED_UID="$(id -u)"
info "This account: ${DETECTED_USER} (uid ${DETECTED_UID})"

HOST_FILE="${CHEZMOI_DIR}/dot_config/nix-darwin/hosts/${PROFILE}.nix"
if [[ -f "${HOST_FILE}" ]] && grep -q 'WORK_USERNAME' "${HOST_FILE}"; then
  warn "${HOST_FILE} still has placeholder account values."
  echo "Set them to this machine's account, commit, then re-run bootstrap:"
  echo "    _module.args.user = \"${DETECTED_USER}\";"
  echo "    _module.args.uid  = ${DETECTED_UID};"
  fail "Edit hosts/${PROFILE}.nix and re-run."
fi
ok "Using account settings from hosts/${PROFILE}.nix"

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
  sudo nix run nix-darwin -- switch --flake "${BOOTSTRAP_FLAKE_DIR}#${PROFILE}"
else
  sudo darwin-rebuild switch --flake "${BOOTSTRAP_FLAKE_DIR}#${PROFILE}"
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

# --- Apple Account sign-in + Xcode ---
step "Apple Account & Xcode"

ICLOUD_ACCOUNT=$(defaults read ~/Library/Preferences/MobileMeAccounts.plist Accounts 2>/dev/null | grep AccountID | head -1 | cut -d '"' -f 2 || true)
if [[ -n "${ICLOUD_ACCOUNT}" ]]; then
  ok "Already signed in as ${ICLOUD_ACCOUNT}"
else
  info "Opening Apple Account sign-in (use 1Password for credentials)..."
  open "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane"
  echo "┌──────────────────────────────────────────────────────┐"
  echo "│  Sign in with your Apple Account in System Settings. │"
  echo "│  Use 1Password to look up your credentials.          │"
  echo "│  This is required to install Xcode from App Store.   │"
  echo "└──────────────────────────────────────────────────────┘"
  read -rp "Press Enter when signed in... " _

  ICLOUD_ACCOUNT=$(defaults read ~/Library/Preferences/MobileMeAccounts.plist Accounts 2>/dev/null | grep AccountID | head -1 | cut -d '"' -f 2 || true)
  if [[ -n "${ICLOUD_ACCOUNT}" ]]; then
    ok "Signed in as ${ICLOUD_ACCOUNT}"
  else
    warn "Could not verify Apple Account sign-in. Xcode install may fail."
  fi
fi

if mas list 2>/dev/null | grep -q "497799835"; then
  ok "Xcode already installed"
else
  info "Installing Xcode from App Store (this may take a while)..."
  mas install 497799835
  ok "Xcode installed"
fi

# --- Apply chezmoi dotfiles ---
step "chezmoi"

if command -v chezmoi &>/dev/null; then
  # Seed the profile so chezmoi matches the nix-darwin build (email still prompts once).
  CHEZMOI_PROFILE="${PROFILE}" chezmoi init --apply
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

Rebuild after config changes (or just run 'rebuild'):
  darwin-rebuild switch --flake ~/.config/nix-darwin#${PROFILE}

Update dotfiles:
  chezmoi update
DONE
