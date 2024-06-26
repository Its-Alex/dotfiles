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
    Host: Latitude 3420
    Kernel: 6.9.1-arch1-1
    Uptime: 13 hours, 33 mins
    Packages: 869 (pacman), 23 (flatpak)
    Shell: zsh 5.9
    Resolution: 1920x1080
    DE: GNOME 46.1
    WM: Mutter
    WM Theme: Flat-Remix-Blue-Dark-fullPanel
    Theme: Numix-Frost [GTK2/3]
    Icons: Numix-Square [GTK2/3]
    Terminal: tmux
    CPU: 11th Gen Intel i7-1165G7 (8) @ 4.700GHz
    GPU: Intel TigerLake-LP GT2 [Iris Xe Graphics]
    Memory: 6613MiB / 15738MiB
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

#### Themes

- [`flat-remix-gnome`](https://github.com/daniruiz/flat-remix-gnome)
- [`Twilight cursors`](https://github.com/yeyushengfan258/Twilight-Cursors)
