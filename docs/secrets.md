# Secret management

Why this repository sources secrets from Bitwarden and delivers them at runtime
through gopass, instead of reading a file-based password manager directly.

## Decision

- **Source of truth:** Bitwarden, read through [rbw](https://github.com/doy/rbw)
  with chezmoi's [`rbw` template functions](https://www.chezmoi.io/reference/templates/bitwarden-functions/rbw/)
  and seeded into gopass at `chezmoi apply` time.
- **Runtime delivery:** gopass, from a local `bitwarden` mount that is never
  pushed anywhere.
- **Kept on libsecret:** the GPG passphrase (pinentry's own store) and whatever
  GNOME applications manage for themselves. The chezmoi-managed path no longer
  calls `secret-tool`.

## Context

- Host: Arch Linux + GNOME; dotfiles managed by chezmoi.
- Secrets are consumed at runtime by the shell (GitLab), the opencode and Claude
  Code MCP servers (Confluence/Jira/Linear/Terraform/Slack), and jj commit signing (GPG).
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
| `bitwarden/slack/xoxc-xoxd` | password (xoxc token), `xoxd` |

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
- Everything else relies on the age agent, which keeps the identity unlocked in
  memory and is supervised: a systemd user unit on the desktop, a pitchfork
  daemon on the headless instance. `age.agent-timeout = 0` keeps it unlocked
  until the agent restarts; after a restart the first interactive `gopass show`
  reloads the identity (one prompt per boot).
- `age.usekeychain` stays off: concurrent reads (several MCP servers starting
  at once) drop the Secret Service D-Bus connection ("Remote peer
  disconnected"), and gopass's on-demand agent spawn cannot be relied on either
  — a SIGKILL'd agent leaves a socket behind that no successor can bind, and
  the spawner discards the agent's stderr, so it degrades silently.

## How it is wired in this repository

- `.chezmoiscripts/linux/run_onchange_after_040-setup-gopass.sh.tmpl` installs the age identity, points
  `mounts.path` at the global store (cloning it from the private repository, or
  creating it on the first machine) and creates the local `bitwarden` mount. Its
  Bitwarden-sourced body only renders once rbw is logged in
  (`.chezmoitemplates/rbw-authenticated`, which reads rbw's local database); without it it prints the
  `rbw login && chezmoi apply` hint, so `rbw login` enables the whole secret path
  and `rbw logout` disables it again. A logged-in but locked rbw asks for the
  master password through pinentry during the apply.
- `.chezmoiscripts/linux/run_onchange_after_041-seed-gopass.sh.tmpl` seeds the `bitwarden` mount. It skips
  an empty Bitwarden value and leaves an unchanged entry alone.
- `.chezmoiscripts/linux/run_onchange_after_042-gopass-age-agent.sh.tmpl` (desktop only) enables and
  restarts `gopass-age-agent.service`
  (`private_dot_config/systemd/user/gopass-age-agent.service`); the headless
  instance runs the agent as a pitchfork daemon instead
  (`private_dot_config/pitchfork/config.toml.tmpl`).
- `04x` runs in the `after` phase: target files (the SSH keys above all) are
  deployed before the store is touched.
- `dot_zshrc.tmpl` exports only ambient secrets (`GITLAB_PERSONAL_ACCESS_TOKEN`)
  from gopass.
- `dot_local/bin/executable_mcp-atlassian-gopass`,
  `dot_local/bin/executable_mcp-remote-linear-gopass`,
  `dot_local/bin/executable_mcp-slack-gopass` and
  `dot_local/bin/executable_mcp-terraform-gopass` read the MCP tokens from
  gopass on demand and `exec` the server, so those tokens never enter the shell
  environment. `private_dot_config/opencode/opencode.json.tmpl` and the Claude
  Code MCP config point at those wrappers.
- rbw, not the official `bw` CLI: every `bw` call costs ~3 s and chezmoi renders
  every template on each apply, while rbw answers from its agent in milliseconds.
  rbw cannot read attachments, so key files come base64-encoded from the vault
  and are decoded by `.chezmoitemplates/bitwarden-file`: each private key in the
  Notes of its own secure note (`SSH - private key`, `SSH - Old - private key`,
  `Relex - SSH - private key`, `GPG - private key`, `GPG - Relex - private key`;
  a field's 5000 encrypted characters cannot hold an RSA key in base64), public
  keys in the `ssh-public-key` hidden field of their item. Store a new key with
  `base64 -w0`, single-line; `b64dec` in the template restores the exact bytes,
  which a multi-line field or note would not survive.
- `.chezmoiscripts/linux/run_onchange_after_034-configure-rbw.sh.tmpl` sets rbw's account email,
  from the `bitwardenEmail` data value: `BW_EMAIL` in the environment, or asked once per machine
  by `.chezmoi.toml.tmpl` — never committed, since the vault login is the phishing-relevant half
  of the account identity and this repository is public. It also sets `lock_timeout`
  to 72 h: the agent holds the keys in memory only, so the master password is
  still asked after a reboot or logout, and any process of the user can read
  secrets while unlocked — the same exposure window the gopass age agent already
  accepts, just longer than rbw's one-hour default.
  The headless instance logs in unattended at first boot when
  `scripts/create-opencode-instance.sh --with-secrets` is given the credentials:
  a scripted pinentry (`incus/cloud-init/user-data.yaml`) answers rbw's prompts
  from the files cloud-init writes, then is removed. An account with two-step
  login cannot be answered that way; `rbw login && chezmoi apply` on first
  connection is then the path.
- `.chezmoiscripts/linux/run_onchange_after_035-setup-gpg.sh.tmpl` still uses `secret-tool`: the GPG
  passphrase belongs to pinentry, not to gopass. It runs before the gopass setup because git signs
  commits (`gpgsign = true`) and the store's first commit happens during `gopass init`.

## Security model

- Everything is encrypted at rest (gopass store, Bitwarden vault, keyring
  database, `.gpg` files).
- The boundary protects against offline and at-rest theft and accidental commits
  — **not** against malware running as the same user. Any such process can query
  gopass or the keyring; with the GPG passphrase cached, it can also decrypt
  anything encrypted to that key. Root can read everything regardless and is out
  of scope.
