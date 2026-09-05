#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    printf "\e[1;31m%s\e[1;0m\n" "Please run this script as root!"
    exit 1
fi

if [[ -d /boot/grub/ ]]; then
    yay -S --noconfirm --needed snapper grub-btrfs inotify-tools
else
    yay -S --noconfirm --needed snapper inotify-tools
fi


if ! snapper list-configs | awk 'NR>2 {print $1}' | grep -qx root; then
    # Snapper refuses to create a config if the name is still listed in
    # SNAPPER_CONFIGS, even when /etc/snapper/configs/root no longer exists.
    # Drop the stale entry so create-config can repopulate it.
    if [[ -f /etc/conf.d/snapper ]] && ! [[ -f /etc/snapper/configs/root ]]; then
        sed -i '/^SNAPPER_CONFIGS=/c\SNAPPER_CONFIGS=""' /etc/conf.d/snapper
    fi

    # snapper create-config wants to create /.snapshots itself, so clear
    # whatever is currently there (leftover mount, plain dir, or subvolume).
    if mountpoint -q /.snapshots; then
        umount /.snapshots
    fi
    if [[ -d /.snapshots ]]; then
        if btrfs subvolume show /.snapshots &>/dev/null; then
            btrfs subvolume delete /.snapshots
        else
            rm -rf /.snapshots
        fi
    fi

    # Create snapper config. This also creates /.snapshots as a subvolume
    # nested in the currently mounted root subvolume (e.g. @), so no fstab
    # entry is needed.
    snapper -c root create-config /
fi

# Configuration snapper configuration
sed -i '/^TIMELINE_LIMIT_HOURLY/c\TIMELINE_LIMIT_HOURLY="1"' /etc/snapper/configs/root
sed -i '/^TIMELINE_LIMIT_DAILY/c\TIMELINE_LIMIT_DAILY="2"' /etc/snapper/configs/root
sed -i '/^TIMELINE_LIMIT_WEEKLY/c\TIMELINE_LIMIT_WEEKLY="1"' /etc/snapper/configs/root
sed -i '/^TIMELINE_LIMIT_MONTHLY/c\TIMELINE_LIMIT_MONTHLY="1"' /etc/snapper/configs/root
sed -i '/^TIMELINE_LIMIT_QUARTERLY/c\TIMELINE_LIMIT_QUARTERLY="0"' /etc/snapper/configs/root
sed -i '/^TIMELINE_LIMIT_YEARLY/c\TIMELINE_LIMIT_YEARLY="0"' /etc/snapper/configs/root

# Enable snapper
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# Make backup each day at 10 and 20
mkdir -p /etc/systemd/system/snapper-timeline.timer.d/
cat <<EOT > /etc/systemd/system/snapper-timeline.timer.d/override.conf
[Timer]
OnCalendar=
OnCalendar=*-*-* 10:00:00 Europe/Paris
OnCalendar=*-*-* 20:00:00 Europe/Paris
EOT

if [[ -d /boot/grub/ ]]; then
    # Enable grub-btrfs
    systemctl enable --now grub-btrfsd
    # Enable booting into read-only snapshots https://wiki.archlinux.org/title/Snapper#Booting_into_read-only_snapshots
    if ! grep -q "HOOKS=.*grub-btrfs-overlayfs" /etc/mkinitcpio.conf; then
        sed -i -e "s/^\(HOOKS=(.*\))/\1 grub-btrfs-overlayfs)/" /etc/mkinitcpio.conf
        mkinitcpio -P
    fi
fi
