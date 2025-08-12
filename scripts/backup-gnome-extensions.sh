#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

# Save extensions
gnome-extensions list --enabled > "./extensions-enabled.txt"

# Save extensions settings
dconf dump /org/gnome/shell/extensions/ > "./gnome-shell-extensions.dconf"
