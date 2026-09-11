# Secret management

Why this repository sources secrets from Bitwarden and delivers them at runtime
through the GNOME keyring (libsecret), instead of reading a file-based password
manager directly.

## Decision

- **Source of truth:** Bitwarden, read through chezmoi's `bitwarden` template
  functions and seeded into the keyring at `chezmoi apply` time.
- **Runtime delivery:** GNOME keyring via libsecret (`secret-tool`).
- **Alternatives considered, not used here:** `gopass`/`pass` (GPG-backed file
  stores; gopass is used by a separate infrastructure repository, not by these
  dotfiles) and `age` (no auto-unlock path; only worth it when dropping GPG).

## Context

- Host: Arch Linux + GNOME; dotfiles managed by chezmoi.
- Secrets are consumed at runtime by the shell (GitLab), the opencode and Claude
  Code MCP servers (Confluence/Jira/Linear), and jj commit signing (GPG).
- Requirements: nothing in cleartext at rest, and no repeated passphrase prompts.

## Why the keyring for delivery

- Encrypted at rest; unlocked automatically at login (PAM unlocks `login.keyring`).
- No prompt and no external dependency at read time.
- Fast: measured ~9 ms per lookup.
- Already holds adjacent credentials: SSH keys (`gcr-ssh-agent` →
  `user.keystore`), the GPG passphrase, and portal application secrets.

## Measured performance

| Command | Per call |
| --- | --- |
| `secret-tool lookup` | ~9 ms |
| `gopass show` | ~274 ms |
| raw `gpg --decrypt` | ~215 ms |
| `/bin/true` baseline | ~0.6 ms |

A GPG file store is roughly 30x slower per read: each lookup spawns a process
chain and performs asymmetric decryption, and the ~215 ms `gpg` cost dominates.
That cost is inherent to GPG, so swapping gopass for `pass` does not help — same
crypto, same floor. It is acceptable for a cold path (seeding, editing, syncing)
and unacceptable for a hot path (shell start-up, per-command lookups), which is
why delivery goes through the keyring.

## Alternatives considered (file stores)

This repository does not read a GPG file store for its secrets; Bitwarden is the
source. The file-store options were still evaluated:

- **gopass vs pass:** the same category. Both are GPG-encrypted files under git
  with an identical security model and the same speed floor, and gopass is
  pass-store compatible. gopass is already used by a separate infrastructure
  repository (`~/Documents/personal-infra-as-code`), not by these dotfiles, so
  there is no reason to introduce `pass` as well.
- **age:** faster (X25519 + ChaCha20, single process, no agent), but it has no
  equivalent auto-unlock and adds an identity key to manage. It only wins if the
  goal is to eliminate GPG entirely.

## How it is wired in this repository

- `run_onchange_00002-seed-gnome-keyring.sh.tmpl` seeds the keyring from Bitwarden
  at `chezmoi apply` time, under `service dotfiles` with `key` set to the
  environment variable name. It is guarded by `CHEZMOI_PASSWORD_MANAGER_DISABLED`.
- `dot_zshrc.tmpl` exports only ambient secrets (`GITLAB_PERSONAL_ACCESS_TOKEN`)
  from the keyring.
- `dot_local/bin/executable_mcp-atlassian-keyring` and
  `dot_local/bin/executable_mcp-remote-linear-keyring` read the MCP tokens from
  the keyring on demand and `exec` the server, so those tokens never enter the
  shell environment.
- `private_dot_config/opencode/opencode.json.tmpl` and the Claude Code MCP config
  point at those wrappers.
- The GPG passphrase is stored by `pinentry-gnome3` under `org.gnupg.Passphrase`;
  it is not managed by this repository.

## Security model

- Everything is encrypted at rest (keyring database, Bitwarden vault, `.gpg`
  files).
- The boundary protects against offline and at-rest theft and accidental commits
  — **not** against malware running as the same user. Any such process can query
  the keyring or invoke `gpg`; with the GPG passphrase cached, it can also decrypt
  anything encrypted to that key (such as the separate gopass store). Root can
  read everything regardless and is out of scope.
