#!/usr/bin/env zsh

set -Eeuo pipefail

ansible-playbook .provision/local.yml --ask-become-pass
