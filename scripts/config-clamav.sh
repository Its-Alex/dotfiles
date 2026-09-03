#!/usr/bin/env bash
set -euo pipefail

# Configure ClamAV with on-access (real-time) scanning.
#
# ClamAV is signature-only with no behavioural detection, and its database is
# overwhelmingly Windows malware, so treat this as a filter for downloaded files
# rather than as host protection. It exists here to satisfy a corporate
# "endpoint must run an anti-malware agent" requirement.
#
# Run manually, it is not applied by chezmoi (scripts/ is in .chezmoiignore):
#   $ sudo ./scripts/config-clamav.sh
#
# Safe to re-run: every file is rewritten and the services restarted.

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
# clamd's temp directory must NOT sit under a watched path: clamd extracts
# archives there, which raises new fanotify events, which create more temp
# files. clamonacc detects the overlap and refuses to watch the path at all,
# silently leaving it unprotected, so /tmp cannot be both watched and used.
clamd_tmp_dir=/var/tmp/clamav

printf "\e[1;34m%s\e[1;0m\n" "Install ClamAV..."
yay -S --noconfirm --needed clamav

printf "\e[1;34m%s\e[1;0m\n" "Create quarantine and clamd temp directories..."
# tmpfiles.d rather than mkdir so /var/tmp/clamav survives systemd's periodic
# /var/tmp cleanup, which would otherwise delete it under a running clamd.
# The package already ships /run/clamav, /var/log/clamav and /var/lib/clamav.
cat <<EOT > /etc/tmpfiles.d/clamav-local.conf
d ${clamd_tmp_dir} 0750 clamav clamav -
d ${quarantine_dir} 0700 root root -
EOT
systemd-tmpfiles --create /etc/tmpfiles.d/clamav-local.conf

printf "\e[1;34m%s\e[1;0m\n" "Configure clamd (on-access scanning)..."
# The whole file is rewritten rather than appended to: clamd.conf has no drop-in
# support and appending is not idempotent, because multi-value directives such
# as OnAccessIncludePath accumulate on every run. Arch's shipped clamd.conf is
# ~30KB of comments around only six active directives, all reproduced below.
# clamd.conf is in pacman's backup array, so upgrades leave a .pacnew rather
# than overwriting this.
cat <<EOT > /etc/clamav/clamd.conf
# Managed by scripts/config-clamav.sh - re-run it instead of editing by hand.
LogFile /var/log/clamav/clamd.log
LogTime yes
PidFile /run/clamav/clamd.pid
LocalSocket /run/clamav/clamd.ctl
User clamav
TemporaryDirectory ${clamd_tmp_dir}

# ---- On-access scanning (clamonacc) ----
# Mandatory: clamonacc exits 2 on startup unless at least one of
# OnAccessExcludeUID / OnAccessExcludeUname / OnAccessExcludeRootUID is set,
# because scanning clamd's own file access is an infinite event loop.
OnAccessExcludeUname clamav
OnAccessExcludeRootUID yes

# Watched recursively. Deliberately narrow: with OnAccessPrevention below every
# write inside these paths blocks until the scan returns. Widening this to all
# of ${target_home} makes git/cargo/npm painful and needs exclusions for
# node_modules, target/, .git and friends. Downloads is where untrusted files
# actually land.
OnAccessIncludePath ${target_home}/Downloads
# /tmp is a common drop location for payloads. Remove this line if the desktop
# stalls: browsers, IDEs and language servers churn heavily in /tmp.
OnAccessIncludePath /tmp

OnAccessExcludePath ${target_home}/.cache
OnAccessExcludePath /var/lib/clamav
OnAccessExcludePath ${clamd_tmp_dir}
OnAccessExcludePath ${quarantine_dir}

# Block access until the scan completes instead of only logging after the fact.
# Requires CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y (checked at the end of this
# script); without it clamonacc degrades to notify-only and cannot stop a read.
OnAccessPrevention yes

# Also scan on create and move, not only on open.
OnAccessExtraScanning yes

# Anything larger is skipped on access. Raising this costs CPU on every large
# file touched inside a watched path.
OnAccessMaxFileSize 50M
EOT

printf "\e[1;34m%s\e[1;0m\n" "Configure freshclam (signature updates)..."
cat <<EOT > /etc/clamav/freshclam.conf
# Managed by scripts/config-clamav.sh - re-run it instead of editing by hand.
UpdateLogFile /var/log/clamav/freshclam.log
PidFile /run/clamav/freshclam.pid
DatabaseMirror database.clamav.net
# Signal clamd to reload after an update, otherwise the running daemon keeps
# matching against the signatures it loaded at boot.
NotifyClamd /etc/clamav/clamd.conf
# Default is 24 checks per day; ClamAV publishes several times a day.
Checks 4
EOT

printf "\e[1;34m%s\e[1;0m\n" "Fetch initial signature database if missing..."
# clamav-daemon.service and .socket both carry ConditionPathExistsGlob on
# main.{cvd,cld,inc} and daily.*, so on a fresh install they silently refuse to
# start until freshclam has run once. ~107MB, so only fetch when truly absent.
database_present=0
for database_file in /var/lib/clamav/daily.cvd /var/lib/clamav/daily.cld /var/lib/clamav/daily.inc; do
    if [[ -e "$database_file" ]]; then
        database_present=1
    fi
done
if [[ "$database_present" -eq 0 ]]; then
    # freshclam.service holds a lock on the database directory, so it has to be
    # stopped for a foreground fetch.
    systemctl stop clamav-freshclam.service 2>/dev/null || true
    freshclam --foreground
fi

printf "\e[1;34m%s\e[1;0m\n" "Override clamonacc service..."
# Two fixes over the packaged unit:
#   --fdpass : clamd runs as the unprivileged `clamav` user and cannot read most
#              of the files it is asked to scan. fd-passing hands it an already
#              open descriptor from root-owned clamonacc instead.
#   --move   : the packaged unit points at /root/quarantine, which nothing
#              creates, so quarantining fails.
# Restart=on-failure covers the transient case where clamd is still loading the
# ~1GiB signature set when clamonacc gives up waiting for its socket.
mkdir -p /etc/systemd/system/clamav-clamonacc.service.d/
cat <<EOT > /etc/systemd/system/clamav-clamonacc.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/clamonacc -F --fdpass --log=/var/log/clamav/clamonacc.log --move=${quarantine_dir}
Restart=on-failure
RestartSec=10
EOT

printf "\e[1;34m%s\e[1;0m\n" "Configure logrotate for clamonacc log..."
# The packaged /etc/logrotate.d/clamav only covers clamd.log, freshclam.log and
# clamav-milter.log, so clamonacc.log would grow unbounded.
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
# clamd before clamonacc: clamonacc reads the OnAccess* directives through
# clamd's socket, so starting it against a stale daemon reapplies nothing.
systemctl restart clamav-daemon.service
systemctl enable clamav-clamonacc.service
systemctl restart clamav-clamonacc.service

printf "\e[1;34m%s\e[1;0m\n" "Verify kernel supports on-access prevention..."
# OnAccessPrevention silently degrades to notify-only without this, which looks
# identical in `systemctl status` but cannot actually block anything.
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
