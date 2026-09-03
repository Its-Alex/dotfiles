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
$ CHEZMOI_PASSWORD_MANAGER_DISABLED=true sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/Its-Alex/dotfiles.git
```

To install dotfiles. The variable `CHEZMOI_PASSWORD_MANAGER_DISABLED` allow me
to perform a full installation without connecting myself because I don't want
to automate this part.

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
- [`System monitor next`](https://extensions.gnome.org/extension/3010/system-monitor-next/)
- [`Extension manager`](https://github.com/mjakeman/extension-manager)

You can find them in [gnome-extensions.txt](./gnome-extensions.txt).

#### Themes

- [`flat-remix-gnome`](https://github.com/daniruiz/flat-remix-gnome)
- [`Twilight cursors`](https://github.com/yeyushengfan258/Twilight-Cursors)

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