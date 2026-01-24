#!/bin/sh

# exit immediately if bw is already in $PATH
type bw >/dev/null 2>&1 && exit

case "$(uname -s)" in
Linux)
    if [ -f /etc/arch-release ]; then
        sudo pacman -S --noconfirm --needed bitwarden-cli
        if [ "$CHEZMOI_PASSWORD_MANAGER_DISABLED" != "true" ] && [ "$CHEZMOI_PASSWORD_MANAGER_DISABLED" != "1" ]; then
            bw login
        fi
    else
        echo "unsupported distribution"
    fi
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac
