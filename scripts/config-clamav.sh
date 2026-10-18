#!/usr/bin/env bash
set -euo pipefail

# Configures ClamAV on-access scanning. Signature-only and mostly Windows
# signatures: a download filter, kept to satisfy a corporate AV requirement.
# Run manually: sudo ./scripts/config-clamav.sh (scripts/ is in .chezmoiignore).

if [[ "$EUID" -ne 0 ]]; then
    printf "\e[1;31m%s\e[1;0m\n" "Please run this script as root!"
    exit 1
fi

# $HOME is root's under sudo, so the account to protect comes from SUDO_USER.
target_user="${SUDO_USER:-}"
if [[ -z "$target_user" || "$target_user" == "root" ]]; then
    printf "\e[1;31m%s\e[1;0m\n" \
        "Cannot determine which user to protect (SUDO_USER is unset or root)." \
        "Run this via sudo from your normal account: sudo ./scripts/config-clamav.sh"
    exit 1
fi
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
if [[ -z "$target_home" || ! -d "$target_home" ]]; then
    printf "\e[1;31m%s\e[1;0m\n" "Home directory for '${target_user}' not found."
    exit 1
fi

quarantine_dir=/var/quarantine
# Not under a watched path: clamd extracts archives there, and the resulting
# fanotify events make clamonacc refuse to watch the path at all (silently).
clamd_tmp_dir=/var/tmp/clamav

printf "\e[1;34m%s\e[1;0m\n" "Install ClamAV..."
yay -S --noconfirm --needed clamav

printf "\e[1;34m%s\e[1;0m\n" "Create quarantine and clamd temp directories..."
# tmpfiles.d, not mkdir: survives systemd's periodic /var/tmp cleanup.
cat <<EOT > /etc/tmpfiles.d/clamav-local.conf
d ${clamd_tmp_dir} 0750 clamav clamav -
d ${quarantine_dir} 0700 root root -
EOT
systemd-tmpfiles --create /etc/tmpfiles.d/clamav-local.conf

printf "\e[1;34m%s\e[1;0m\n" "Configure clamd (on-access scanning)..."
# Rewritten, not appended: clamd.conf has no drop-in support and multi-value
# directives accumulate. It is in pacman's backup array, so upgrades leave a
# .pacnew rather than overwriting this.
cat <<EOT > /etc/clamav/clamd.conf
# Managed by scripts/config-clamav.sh - re-run it instead of editing by hand.
LogFile /var/log/clamav/clamd.log
LogTime yes
PidFile /run/clamav/clamd.pid
LocalSocket /run/clamav/clamd.ctl
User clamav
TemporaryDirectory ${clamd_tmp_dir}

# ---- On-access scanning (clamonacc) ----
# Mandatory: without an OnAccessExclude*, clamonacc exits 2 on startup (scanning
# clamd's own file access is an infinite event loop).
OnAccessExcludeUname clamav
OnAccessExcludeRootUID yes

# Deliberately narrow: with OnAccessPrevention every write here blocks until the
# scan returns, so watching all of ${target_home} stalls git/cargo/npm.
OnAccessIncludePath ${target_home}/Downloads
# Common payload drop location; remove if the desktop stalls on /tmp churn.
OnAccessIncludePath /tmp

OnAccessExcludePath ${target_home}/.cache
OnAccessExcludePath /var/lib/clamav
OnAccessExcludePath ${clamd_tmp_dir}
OnAccessExcludePath ${quarantine_dir}

# Block until the scan completes. Needs CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y
# (checked at the end); otherwise it degrades to notify-only.
OnAccessPrevention yes

# Also scan on create and move, not only on open.
OnAccessExtraScanning yes

# Larger files are skipped; raising this costs CPU on every large file touched.
OnAccessMaxFileSize 50M
EOT

printf "\e[1;34m%s\e[1;0m\n" "Configure freshclam (signature updates)..."
cat <<EOT > /etc/clamav/freshclam.conf
# Managed by scripts/config-clamav.sh - re-run it instead of editing by hand.
UpdateLogFile /var/log/clamav/freshclam.log
PidFile /run/clamav/freshclam.pid
DatabaseMirror database.clamav.net
# Without this clamd keeps matching the signatures it loaded at boot.
NotifyClamd /etc/clamav/clamd.conf
# Default is 24 checks per day; ClamAV publishes several times a day.
Checks 4
EOT

printf "\e[1;34m%s\e[1;0m\n" "Fetch initial signature database if missing..."
# The packaged units carry ConditionPathExistsGlob on the database files, so they
# silently refuse to start until freshclam has run once (~107MB).
database_present=0
for database_file in /var/lib/clamav/daily.cvd /var/lib/clamav/daily.cld /var/lib/clamav/daily.inc; do
    if [[ -e "$database_file" ]]; then
        database_present=1
    fi
done
if [[ "$database_present" -eq 0 ]]; then
    # freshclam.service locks the database directory, so stop it for the fetch.
    systemctl stop clamav-freshclam.service 2>/dev/null || true
    freshclam --foreground
fi

printf "\e[1;34m%s\e[1;0m\n" "Override clamonacc service..."
# Over the packaged unit: --fdpass hands the unprivileged clamd an open
# descriptor from root-owned clamonacc, and --move points at a quarantine dir
# that exists. Restart=on-failure covers clamd still loading its signatures when
# clamonacc gives up waiting for the socket.
mkdir -p /etc/systemd/system/clamav-clamonacc.service.d/
cat <<EOT > /etc/systemd/system/clamav-clamonacc.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/clamonacc -F --fdpass --log=/var/log/clamav/clamonacc.log --move=${quarantine_dir}
Restart=on-failure
RestartSec=10
EOT

printf "\e[1;34m%s\e[1;0m\n" "Configure logrotate for clamonacc log..."
# The packaged logrotate config omits clamonacc.log, which would grow unbounded.
cat <<'EOT' > /etc/logrotate.d/clamav-local
/var/log/clamav/clamonacc.log {
	weekly
	rotate 4
	compress
	delaycompress
	missingok
	notifempty
	create 640 clamav clamav
}
EOT

printf "\e[1;34m%s\e[1;0m\n" "Enable ClamAV services..."
systemctl daemon-reload
systemctl enable --now clamav-freshclam.service
systemctl enable --now clamav-daemon.socket clamav-daemon.service
# clamd first: clamonacc reads OnAccess* through clamd's socket.
systemctl restart clamav-daemon.service
systemctl enable clamav-clamonacc.service
systemctl restart clamav-clamonacc.service

printf "\e[1;34m%s\e[1;0m\n" "Verify kernel supports on-access prevention..."
# Without this, OnAccessPrevention silently degrades to notify-only.
kernel_config="$( (zcat /proc/config.gz 2>/dev/null || cat "/boot/config-$(uname -r)" 2>/dev/null) || true )"
if [[ -n "$kernel_config" ]] && ! grep -q '^CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y' <<< "$kernel_config"; then
    printf "\e[1;31m%s\e[1;0m\n" \
        "WARNING: CONFIG_FANOTIFY_ACCESS_PERMISSIONS is not enabled in this kernel." \
        "  OnAccessPrevention cannot block access; clamonacc will only log and quarantine."
fi

printf "\e[1;32m%s\e[1;0m\n" \
    "ClamAV configured. Verify real-time protection actually blocks:" \
    "  curl -s https://secure.eicar.org/eicar.com -o ${target_home}/Downloads/eicar.com" \
    "  cat ${target_home}/Downloads/eicar.com   # expect: Operation not permitted" \
    "  sudo ls ${quarantine_dir}"
