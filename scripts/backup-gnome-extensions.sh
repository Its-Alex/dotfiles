#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

gnome-extensions list --enabled > "./gnome-extensions.txt"

dconf dump /org/gnome/shell/extensions/ > "./gnome-shell-extensions.dconf"
