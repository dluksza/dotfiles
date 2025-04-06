#!/usr/bin/env bash

set -Eeuo pipefail

cd .local/share/chezmoi

./.00-install-presto.sh
