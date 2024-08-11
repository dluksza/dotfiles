#!/usr/bin/env zsh

set -Eeuo pipefail

ansible-galaxy install -r .provision/requirements.yml
ansible-playbook .provision/local.yml --ask-become-pass
