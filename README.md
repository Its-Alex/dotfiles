# Dotfiles

This repo contains all my configuration.

## Requirements

- [`chezmoi`](https://github.com/twpayne/chezmoi)

## Getting started

To execute a first install, use:

```sh-session
$ sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Its-Alex/dotfiles.git
```

To update your current configuration:

```sh-session
$ chezmoi apply
```

### Machine role

Each machine records a role, `desktop` or `headless`. It is asked once at
`chezmoi init` and persisted in `~/.config/chezmoi/chezmoi.toml`. Set
`CHEZMOI_ROLE` to answer without prompting:

```sh-session
$ CHEZMOI_ROLE=headless sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Its-Alex/dotfiles.git
```

`CHEZMOI_ROLE` is read only while `chezmoi init` renders the config template;
the value persists in the config file and plain `apply`/`update` ignore the
variable. Re-run `chezmoi init` with the variable set to change a machine's
role, the variable wins over the persisted answer. Any other value aborts the
init with the list of allowed roles.

### Bitwarden account email

`chezmoi init` also asks once for the Bitwarden account email, persisted the
same way and never committed (this repository is public). `BW_EMAIL` answers
without prompting, like `CHEZMOI_ROLE` for the role. On a terminal-less init
with no `BW_EMAIL` the question is skipped and no email is recorded; the next
interactive `chezmoi init` asks again.

### Secrets

Secrets (SSH/GPG keys, API tokens) come from Bitwarden through
[rbw](https://github.com/doy/rbw), which the pre-apply hook installs. While rbw
is not logged in, an apply simply skips every secret-dependent part. Enable
them with:

```sh-session
$ rbw login && chezmoi apply
```

`rbw logout` returns the machine to secretless applies. See
[`docs/secrets.md`](./docs/secrets.md) for the design.

## Install from scratch

To install from scratch I use [QEMU Archlinux](https://github.com/Its-Alex/qemu-archlinux),
when the VM is setup I enable `pinentry-curses` using:

```shell
$ mkdir -p ~/.gnupg/ && \
    echo 'pinentry-program /usr/bin/pinentry-curses' >> ~/.gnupg/gpg-agent.conf && \
    echo 'allow-loopback-pinentry' >> ~/.gnupg/gpg-agent.conf && \
    echo 'pinentry-mode loopback' >> ~/.gnupg/gpg.conf && \
    export GPG_TTY=$(tty) && \
    gpgconf --kill gpg-agent
```

This allow for GPG password to be entered in shell for development purpose. I
also enable rootless password to prevent putting password everytime:

```shell
$ echo 'archlinux ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/90-archlinux-nopasswd >/dev/null && \
    sudo chmod 0440 /etc/sudoers.d/90-archlinux-nopasswd
```

Finally I can launch:

```shell
$ sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Its-Alex/dotfiles.git
```

To install dotfiles. Everything secret-dependent is skipped as long as rbw is
not logged in (see [Secrets](#secrets)), so this performs a full installation
without connecting to Bitwarden.

## Configurations

Today I mainly use two computer:

- Home computer, a dualboot Windows/Linux, running ArchLinux
    ```sh
    $ neofetch --stdout
    OS: Arch Linux x86_64
    Host: MS-7C91 2.0
    Kernel: 6.7.9-arch1-1
    Uptime: 2 hours, 29 mins
    Packages: 1498 (pacman), 22 (flatpak)
    Shell: zsh 5.9
    Resolution: 2560x1440
    DE: GNOME 45.4
    WM: Mutter
    WM Theme: Flat-Remix-Blue-Dark-fullPanel
    Theme: Numix-Frost [GTK2/3]
    Icons: Numix-Square [GTK2/3]
    Terminal: tmux
    CPU: AMD Ryzen 9 5900X (24) @ 3.700GHz
    GPU: NVIDIA GeForce RTX 4080 SUPER
    Memory: 7726MiB / 32018MiB
    ```
- Work computer
    ```sh
    $ neofetch --stdout
    OS: Arch Linux x86_64
    Host: 21RV001RFR ThinkPad P14s Gen 6 AMD
    Kernel: 7.2.2-arch1-1
    Uptime: 30 mins
    Packages: 1099 (pacman), 17 (flatpak)
    Shell: zsh 5.9.2
    Resolution: 1920x1200
    DE: GNOME 50.4
    WM: Mutter
    WM Theme: Adwaita
    Theme: Numix-Frost [GTK2/3]
    Icons: Numix-Square [GTK2/3]
    Terminal: tmux
    CPU: AMD Ryzen AI 9 HX PRO 370 w/ Radeon 890M (24) @ 5.157GHz
    GPU: AMD ATI Radeon 880M / 890M
    Memory: 5330MiB / 59896MiB
    ```


## Documentation

Repository-only documentation lives in [`docs/`](./docs): the rationale and design
notes behind configuration decisions, for example
[`docs/secrets.md`](./docs/secrets.md) on why secrets are delivered through
gopass, and [`docs/scripts.md`](./docs/scripts.md) on how the `run_*` scripts in
[`.chezmoiscripts/linux/`](./.chezmoiscripts/linux) are named and ordered.

`docs/` is listed in [`.chezmoiignore`](./.chezmoiignore) and is never deployed,
like the other repository-only files (`README.md`, `AGENTS.md`, `scripts/`, ...).

## Linux

### Gnome

#### Tips

If the ssh agent is not started, execute:

```sh
$ systemctl --user enable gcr-ssh-agent.socket
```

#### Extensions

- [`Dash to dock`](https://micheleg.github.io/dash-to-dock/)
- [`GNOME Fuzzy App Search`](https://extensions.gnome.org/extension/3956/gnome-fuzzy-app-search/)
- [`Grand Theft Focus`](https://extensions.gnome.org/extension/5410/grand-theft-focus/)
- [`Night Theme Switcher`](https://extensions.gnome.org/extension/2236/night-theme-switcher/)
- [`System monitor next`](https://extensions.gnome.org/extension/3010/system-monitor-next/)
- [`Extension manager`](https://github.com/mjakeman/extension-manager)

You can find them in [gnome-extensions.txt](./gnome-extensions.txt).

#### Themes

- [`flat-remix-gnome`](https://github.com/daniruiz/flat-remix-gnome)
- [`Twilight cursors`](https://github.com/yeyushengfan258/Twilight-Cursors) (installed from [my fork](https://github.com/Its-Alex/Twilight-Cursors/tree/gnome-51-svg-cursors) until [#2](https://github.com/yeyushengfan258/Twilight-Cursors/pull/2) is merged)

### Snapper

To configure [Snapper](https://wiki.archlinux.org/title/Snapper) on Archlinux you
can use:

```shell
$ ./scripts/config-snapper.sh
```

### ClamAV

To configure [ClamAV](https://docs.clamav.net/) with on-access (real-time)
scanning and a weekly scan, use:

```shell
$ sudo ./scripts/config-clamav.sh
```

This is only needed on the work computer, where an anti-malware agent is
required. It is safe to re-run. Notes:

- Real-time scanning watches `~/Downloads` and `/tmp` only, and blocks access
  until the scan returns. Remove the `OnAccessIncludePath /tmp` line from the
  script if the desktop stalls, since browsers and IDEs churn heavily there.
- Detections are moved to `/var/quarantine`. Check it before assuming a hit is
  real, false positives on build artifacts are common.
- `clamd` keeps ~1GiB resident to hold the signature database.
- Verify it actually blocks, rather than just running:

    ```shell
    $ curl -s https://secure.eicar.org/eicar.com -o ~/Downloads/eicar.com
    $ cat ~/Downloads/eicar.com   # expect: Operation not permitted
    ```

### Incus

`012-host-system` installs [Incus](https://linuxcontainers.org/incus/), enables
`incus.socket`, adds the user to `incus-admin`, and installs
[`incus-apply`](https://incus-apply.abiosoft.com/) (no AUR package, so the pinned
upstream release binary goes to `/usr/local/bin`). Two steps stay manual:

- Log out and back in after the first apply: group membership only reaches a new
  session.
- Initialise the daemon once. It creates the default storage pool and the
  `incusbr0` bridge, and is left out of the script so the storage backend is not
  guessed:

    ```sh-session
    $ incus admin init --minimal
    ```

#### VMs inside an instance

Nested virtualisation has to be enabled on the host for an Incus instance to
start VMs of its own:

```sh-session
$ cat /sys/module/kvm_amd/parameters/nested   # AMD; Intel: kvm_intel
1
```

Without it the instance still runs system containers, but `vm: true` instances it
creates inside fail to boot.

The `opencode` profile leaves `security.nesting` unset, so each kind gets its
default: a VM can nest (`/dev/kvm`, `svm`/`vmx` in `/proc/cpuinfo`), a
`--container` instance cannot, and podman or incus inside such a container needs
`security.nesting=true` set on it explicitly.

### OpenChamber

The desktop keeps OpenChamber Desktop, the Electron AppImage at
`/opt/openchamber/OpenChamber.AppImage`. A headless machine installs the other
half instead: the [`@openchamber/web`](https://www.npmjs.com/package/@openchamber/web)
CLI, the server the desktop app bundles, installed through mise and serving on
port 3000. It is supervised by pitchfork next to ssh-agent:

```sh-session
$ pitchfork status global/openchamber
```

`boot_start` plus linger (both from the pitchfork setup) is what brings it back
after a reboot, not the chezmoi apply.

Reaching it:

- Bind address `0.0.0.0`, so any tailnet device can open
  `http://<instance>:3000`. The browser asks for the password kept in
  `~/.local/state/openchamber/ui-password` on the instance; it is generated there
  on the first apply and never enters this repository.
- To add it to OpenChamber Desktop as a remote instance, generate a pairing link
  on the instance and import it at Settings → Remote Instances → Other OpenChamber
  servers → Import Link:

    ```sh-session
    $ openchamber connect-url --port 3000 --server http://<instance>:3000 --qr
    ```

    The link carries a one-time pairing secret; each device then holds its own
    token, revocable from the server's Remote Instances settings.

Upgrading is `mise upgrade` on the instance, then `pitchfork restart
global/openchamber` (or a reboot: `boot_start` re-resolves the tool at every
start). `latest` in mise is not a rolling update — `mise install` keeps the
version it already has until an explicit `mise upgrade` — so the server only moves
when you move it. `openchamber update` is not used, it would install outside mise.