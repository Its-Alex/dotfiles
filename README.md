# Dotfiles

This repo contains all my configuration.

## Requirements

- [`chezmoi`](https://github.com/twpayne/chezmoi)
- [`mise`](https://github.com/jdx/mise)

## Install

First you must allow direnv environment:

```sh
$ mise install
$ direnv allow
```

You will be asked to prompt your bitwarden email and password, this is for
files that can contain secrets.

## Linux

### Scripts

There are scripts to install some packages on Linux:

- [`archlinux-gnome-install.sh`](archlinux-gnome-install.sh) for Archlinux with gnome

### Gnome

#### Extensions

- [`Dash to dock`](https://micheleg.github.io/dash-to-dock/)
- [`GNOME Fuzzy App Search`](https://extensions.gnome.org/extension/3956/gnome-fuzzy-app-search/)
- [`Grand Theft Focus`](https://extensions.gnome.org/extension/5410/grand-theft-focus/)
- [`System monitor next`](https://extensions.gnome.org/extension/3010/system-monitor-next/)

#### Themes

- [`flat-remix-gnome`](https://www.gnome-look.org/p/1013030/)
