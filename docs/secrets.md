# Secret management

Why this repository sources secrets from Bitwarden and delivers them at runtime
through gopass, instead of reading a file-based password manager directly.

## Decision

- **Source of truth:** Bitwarden, read through chezmoi's `bitwarden` template
  functions and seeded into gopass at `chezmoi apply` time.
- **Runtime delivery:** gopass, from a local `bitwarden` mount that is never
  pushed anywhere.
- **Kept on libsecret:** the GPG passphrase (pinentry's own store) and whatever
  GNOME applications manage for themselves. The chezmoi-managed path no longer
  calls `secret-tool`.

## Context

- Host: Arch Linux + GNOME; dotfiles managed by chezmoi.
- Secrets are consumed at runtime by the shell (GitLab), the opencode and Claude
  Code MCP servers (Confluence/Jira/Linear/Terraform), and jj commit signing (GPG).
- Requirements: nothing in cleartext at rest, and no repeated passphrase prompts.

## Why gopass for delivery

- Encrypted at rest (age), with git versioning available for the secrets that
  live only in gopass.
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

| Store | Path | Storage | Holds |
| --- | --- | --- | --- |
| Global (root) | `~/.local/share/gopass/stores/root` | git, `Its-Alex/password-store` | personal secrets whose source of truth is gopass |
| `bitwarden` mount | `~/.local/share/gopass/stores/bitwarden` | local files, no git | copies of the Bitwarden items the dotfiles consume |
| Repository-scoped | `~/Documents/personal-infra-as-code/passwords` | committed in that repository | the infrastructure credentials its Ansible/OpenTofu code consumes |

The `bitwarden` mount is deliberately not versioned: Bitwarden is its source
and every machine rebuilds it at `chezmoi apply` time, so pushing it would only
expose the entries (several are work credentials) for no benefit. It needs no
backup for the same reason. Never edit it by hand: the next change in Bitwarden
overwrites it.

Its entries are named after the service, one per Bitwarden item. The password is
the first line and extra fields are `key: value` lines:

| Entry | Lines |
| --- | --- |
| `bitwarden/gitlab/api-token` | password |
| `bitwarden/linear/api-key` | password |
| `bitwarden/terraform/api-token` | password |
| `bitwarden/atlassian/confluence` | password, `url`, `username` |
| `bitwarden/atlassian/jira` | password, `url`, `username` |

Read the password with `gopass show --password <entry>` and a field with
`gopass show <entry> <key>`.

The repository-scoped store is selected in that repository's `.mise.toml` by
overriding `mounts.path` with `GOPASS_CONFIG_COUNT`/`GOPASS_CONFIG_KEY_0`/
`GOPASS_CONFIG_VALUE_0`, which outrank every config file. `PASSWORD_STORE_DIR`
does not work for this, because `mounts.path` takes priority over it. Nor does
`GOPASS_CONFIG`: despite its documentation it is read relative to `$HOME`, and
only when `~/.config/gopass/config` does not exist
([gopasspw/gopass#3674](https://github.com/gopasspw/gopass/issues/3674)).

## Passphrase handling

- Chezmoi-managed calls pass `GOPASS_AGE_PASSWORD` (read from Bitwarden), so an
  apply never prompts.
- Interactive use relies on `age.usekeychain` (the passphrase cached in the OS
  keyring) and on the age agent, which keeps the identity unlocked in memory.

## How it is wired in this repository

- `run_onchange_00002-setup-gopass.sh.tmpl` installs the age identity, points
  `mounts.path` at the global store (cloning it from the private repository, or
  creating it on the first machine) and creates the local `bitwarden` mount. It
  is guarded by `CHEZMOI_PASSWORD_MANAGER_DISABLED`.
- `run_onchange_00004-seed-gopass.sh.tmpl` seeds the `bitwarden` mount. It skips
  an empty Bitwarden value and leaves an unchanged entry alone.
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
