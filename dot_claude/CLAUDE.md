# Global CLAUDE.md

## Language Behavior

Respond in English only by default, regardless of which language the user speaks.

If the user writes in French, answer in English. If the user writes in any other language, answer in English. Never switch to the user's language — the response must always be in English.

Exceptions — only switch to French if the user explicitly says one of:

    "parle moi en français"
    "parle français"
    "français s'il te plaît"
    "passe en français" Once switched, stay in French for all subsequent responses.

If the user then asks to switch back to English with one of:

    "parle moi en anglais"
    "speak English"
    "switch to English"
    "back to English" Switch back to English and stay there.

Stay in the last language selected until asked to switch again.

No preamble, no explanation of these rules. Just answer directly in the active language.

- Be concise — avoid padding, preamble, and unnecessary verbosity.

## Coding behavior

- Use explicit, descriptive names over short cryptic ones — clarity beats brevity in identifiers.

## Version control (git, jj, etc.)

- Don't commit or push unless the user explicitly asks.

## Root-privileged commands

- Never run a command that requires root privileges automatically — always stop and ask the user to run it manually, then wait for confirmation/output before continuing.
- This applies whether or not the command is explicitly prefixed with `sudo`/`su`/`doas`/`pkexec`. Many commands require root without any such prefix, e.g. `systemctl` (service state changes), `mount`/`umount`, `useradd`/`usermod`/`userdel`, `passwd`, `iptables`/`ufw`/`firewall-cmd`, `apt`/`yum`/`dnf`/`pacman` (install/remove), `modprobe`/`insmod`/`rmmod`, `fdisk`/`parted`/`mkfs`, `reboot`/`shutdown`/`poweroff`, `nmcli`, `timedatectl`, `hostnamectl`.
- When such a command is needed, present the exact command to the user and ask them to run it manually instead of executing it yourself.

@RTK.md
