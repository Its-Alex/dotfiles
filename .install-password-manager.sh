#!/bin/sh

type bw >/dev/null 2>&1 && exit 0

case "$(uname -s)" in
Linux)
    _os_id=""
    if [ -f /etc/os-release ]; then
        _os_id="$(. /etc/os-release && echo "$ID")"
    elif [ -f /usr/lib/os-release ]; then
        _os_id="$(. /usr/lib/os-release && echo "$ID")"
    fi
    if [ "$_os_id" = "arch" ]; then
        sudo pacman -S --noconfirm --needed bitwarden-cli
        # An unattended apply (cloud-init, cron) has no tty: a login prompt
        # there would hang it forever.
        if [ -t 0 ] && [ "$CHEZMOI_PASSWORD_MANAGER_DISABLED" != "true" ] && [ "$CHEZMOI_PASSWORD_MANAGER_DISABLED" != "1" ]; then
            bw login
        fi
    else
        echo "unsupported distribution"
    fi
    ;;
*)
    echo "unsupported OS"
    ;;
esac

exit 0
