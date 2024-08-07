#!/usr/bin/env bash

set -Eeuo pipefail

echo 'Updating system ...'
sudo /usr/sbin/softwareupdate --install --all --restart >/dev/null 2>&1
echo 'DONE'

if ! (xcode-select -p >/dev/null 2>&1); then
    echo 'Installing Command Line Tools (you can track progress in System Settings > General > Software Update)...'
    /usr/bin/xcode-select --install >/dev/null 2>&1
    /usr/sbin/softwareupdate --install --all
    printf '\tAccept Xcode license'
    sudo /usr/bin/xcodebuild -license accept
    echo ' DONE'
fi

if ! $(command -v brew >/dev/null 2>&1); then
    printf 'Installing HomeBrew ...'
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo ' DONE'
fi

if ! $(command -v ansible >/dev/null 2>&1); then
    printf 'Installing Ansible ...'
    /opt/homebrew/bin/brew install ansible
    echo ' DONE'
fi

if ! [ -e /Applications/1Password.app ]; then
    printf 'Installing 1Password'
    /opt/homebrew/bin/brew install 1password 1password-cli
    echo ' DONE'
fi

if ! $(command -v chezmoi >/dev/null 2>&1); then
    printf 'Installing chezmoi ...'
    /opt/homebrew/bin/brew install chezmoi
    echo ' DONE'
fi

echo 'Provision Dev System'
/opt/homebrew/bin/chezmoi init https://github.com/dluksza/dotfiles.git --use-builtin-git true
/opt/homebrew/bin/chezmoi apply
