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
- Never include ticket numbers (e.g. JIRA/Linear IDs like `ABC-123`) in code (comments, strings, identifiers). Ticket numbers belong in commit messages, branch names, and PR titles/descriptions — not in the code itself.

## Comments

- Default to no comment. The name, the value or the call usually says it already: write nothing.
- A comment must earn its line, and only for one of these — each also names the failure a reader would cause without it:
  - an external constraint (tool, OS, library) that makes the code look wrong: a silent failure, a required order, a flag that must not be passed, a directive that is ignored;
  - an invariant a reader must not "fix" — security, data loss, idempotency;
  - a machine-read directive (lint or schema pragma);
  - "generated — re-run, do not edit" at the top of a generated file.
- Delete on sight: restated names and titles, section labels (`# Helpers`), doc links, change history, prose justifying a choice the code already shows, usage docs for a function that reads plainly, commented-out code.
- One line, two at most. If it needs more, the detail goes in `docs/` and the comment becomes a one-line pointer — or nothing.
- Unsure whether to keep one? Cut it. A missing comment costs a question; a redundant one costs every reader after.

## Referencing and links

- Every reference to an external resource is a link carried by its own text, never a bare identifier: `[#40108](https://github.com/owner/repo/pull/40108)`, `[owner/repo#40108](…)`, `[file.py:42](…)`, `[Python 3.13 release notes](…)`. A `#40108`, an issue key, a CVE, a version or a package name standing alone without a link is a defect, not a citation.
- Cite documentation with the most specific URL, including the anchor/fragment — e.g. `https://opencode.ai/docs/plugins/#create-a-plugin` rather than the page root.
- For GitHub (or GitLab, etc.) references, link the item itself — the PR/issue/commit URL rather than just `#40108`, and a file at a specific revision/line rather than a path alone.
- Link packages, releases, discussions, and standards to their canonical source too.
- Only link targets you are confident are correct; never invent or guess a URL. That is the one case where an identifier stays bare: say plainly that no URL could be confirmed, instead of dropping the link silently.

## Version control (git, jj, etc.)

- Don't commit or push unless the user explicitly asks.

## Root-privileged commands

- Never run a command that requires root privileges automatically — always stop and ask the user to run it manually, then wait for confirmation/output before continuing.
- This applies whether or not the command is explicitly prefixed with `sudo`/`su`/`doas`/`pkexec`. Many commands require root without any such prefix, e.g. `systemctl` (service state changes), `mount`/`umount`, `useradd`/`usermod`/`userdel`, `passwd`, `iptables`/`ufw`/`firewall-cmd`, `apt`/`yum`/`dnf`/`pacman` (install/remove), `modprobe`/`insmod`/`rmmod`, `fdisk`/`parted`/`mkfs`, `reboot`/`shutdown`/`poweroff`, `nmcli`, `timedatectl`, `hostnamectl`.
- When such a command is needed, present the exact command to the user and ask them to run it manually instead of executing it yourself.
