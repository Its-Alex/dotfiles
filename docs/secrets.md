# Secret management

Why this repository sources secrets from Bitwarden and delivers them at runtime
through gopass, instead of reading a file-based password manager directly.

## Decision

- **Source of truth:** Bitwarden, read through chezmoi's `bitwarden` template
  functions and seeded into gopass at `chezmoi apply` time.
- **Runtime delivery:** gopass, an age-encrypted, git-backed file store.
- **Kept on libsecret:** the GPG passphrase (pinentry's own store) and whatever
  GNOME applications manage for themselves. The chezmoi-managed path no longer
  calls `secret-tool`.

## Context

- Host: Arch Linux + GNOME; dotfiles managed by chezmoi.
- Secrets are consumed at runtime by the shell (GitLab), the opencode and Claude
  Code MCP servers (Confluence/Jira/Linear/Terraform), and jj commit signing (GPG).
- Requirements: nothing in cleartext at rest, and no repeated passphrase prompts.

## Why gopass for delivery

- Encrypted at rest (age) and versioned in git, so every change is auditable and
  recoverable.
- Portable: a single static binary on Linux, macOS and Windows, independent of a
  desktop session or D-Bus.
- Fast enough once the age agent holds the unlocked identity: ~12 ms per read,
  against ~575 ms when the identity is re-derived on every call.
- One store for the whole system, shared with the shell, the editors and any
  script that can call `gopass show`.

## Measured performance

| Command | Per call |
| --- | --- |
| `secret-tool lookup` | ~9 ms |
| `gopass show` (age agent warm) | ~12 ms |
| `gopass show` (agentless) | ~575 ms |

## Stores

- **Global store** — `~/.local/share/gopass/stores/root`, backed by the private
  `Its-Alex/password-store` repository. Holds everything this repository seeds
  (`dotfiles/*`) as well as personal secrets.
- **Repository-scoped store** — `~/Documents/personal-infra-as-code/passwords`,
  selected with a `GOPASS_CONFIG_KEY_0`/`_VALUE_0` override in that
  repository's `.env.sh`. Holds the infrastructure credentials its
  Ansible/OpenTofu code consumes.

`mounts.path` takes priority over the pass-compatible `PASSWORD_STORE_DIR`, so
the repository-scoped store is selected by overriding `mounts.path` with
`GOPASS_CONFIG_KEY_0`/`_VALUE_0` (which outranks every config file) rather than
with `PASSWORD_STORE_DIR`. The `GOPASS_CONFIG` file-path variable is not
honoured by gopass 1.17.2 and must not be used for this.

## Passphrase handling

- Chezmoi-managed calls pass `GOPASS_AGE_PASSWORD` (read from Bitwarden), so an
  apply never prompts.
- Interactive use relies on `age.usekeychain` (the passphrase cached in the OS
  keyring) and on the age agent, which keeps the identity unlocked in memory.

## How it is wired in this repository

- `run_onchange_00002-setup-gopass.sh.tmpl` installs the age identity, points
  `mounts.path` at the global store and clones it from the private repository.
  It is guarded by `CHEZMOI_PASSWORD_MANAGER_DISABLED`.
- `run_onchange_00004-seed-gopass.sh.tmpl` seeds `dotfiles/*` from Bitwarden.
- `dot_zshrc.tmpl` exports only ambient secrets (`GITLAB_PERSONAL_ACCESS_TOKEN`)
  from gopass.
- `dot_local/bin/executable_mcp-atlassian-gopass`,
  `dot_local/bin/executable_mcp-remote-linear-gopass` and
  `dot_local/bin/executable_mcp-terraform-gopass` read the MCP tokens from
  gopass on demand and `exec` the server, so those tokens never enter the shell
  environment. `private_dot_config/opencode/opencode.json.tmpl` and the Claude
  Code MCP config point at those wrappers.
- `run_onchange_00005-setup-gpg.sh.tmpl` still uses `secret-tool`: the GPG
  passphrase belongs to pinentry, not to gopass.

## Security model

- Everything is encrypted at rest (gopass store, Bitwarden vault, keyring
  database, `.gpg` files).
- The boundary protects against offline and at-rest theft and accidental commits
  — **not** against malware running as the same user. Any such process can query
  gopass or the keyring; with the GPG passphrase cached, it can also decrypt
  anything encrypted to that key. Root can read everything regardless and is out
  of scope.
