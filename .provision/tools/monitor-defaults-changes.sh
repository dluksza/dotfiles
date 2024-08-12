#!/usr/bin/env bash

defaults read >/tmp/base.defaults.plist

echo "Modify preferences, then press enter to see modifications in defaults"
read

defaults read >/tmp/modified.defaults.plist

diff -Nu /tmp/base.defaults.plist /tmp/modified.defaults.plist
