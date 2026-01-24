#!/bin/sh

# exit immediately if bw is already in $PATH
type bw >/dev/null 2>&1 && exit

case "$(uname -s)" in
Linux)
    # Check os-release in standard locations
    _os_id=""
    if [ -f /etc/os-release ]; then
        _os_id="$(. /etc/os-release && echo "$ID")"
    elif [ -f /usr/lib/os-release ]; then
        _os_id="$(. /usr/lib/os-release && echo "$ID")"
    fi
    if [ "$_os_id" = "arch" ]; then
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
