#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    printf "\e[1;31m%s\e[1;0m\n" "Please run this script as root!"
    exit 1
fi

yay -S --noconfirm --needed snapper grub-btrfs inotify-tools

if [[ "$(snapper list-configs | grep -c root)" == "0" ]]; then
    # Umount default subvolume /.snapshots to let snapper create subvolume
    # https://wiki.archlinux.org/title/Snapper#Configuration_of_snapper_and_mount_point
    if [[ -d /.snapshots ]]; then
        umount /.snapshots
        rm -r /.snapshots
    fi

    # Create snapper config
    snapper -c root create-config /

    # Remove volume created by snapper
    btrfs subvolume delete /.snapshots

    # Mount default subvolume /.snapshots
    mkdir /.snapshots
    mount -a
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
# Enable grub-btrfs
systemctl enable --now grub-btrfsd

# Make backup each day at 10 and 20
mkdir -p /etc/systemd/system/snapper-timeline.timer.d/
cat <<EOT > /etc/systemd/system/snapper-timeline.timer.d/override.conf
[Timer]
OnCalendar=
OnCalendar=*-*-* 10:00:00 Europe/Paris
OnCalendar=*-*-* 20:00:00 Europe/Paris
EOT

# Enable booting into read-only snapshots https://wiki.archlinux.org/title/Snapper#Booting_into_read-only_snapshots
if ! grep -q "HOOKS=.*grub-btrfs-overlayfs" /etc/mkinitcpio.conf; then
    sed -i -e "s/^\(HOOKS=(.*\))/\1 grub-btrfs-overlayfs)/" /etc/mkinitcpio.conf
    mkinitcpio -P
fi
