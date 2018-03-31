#!/bin/sh

echo "Configure os..."

echo "Locale..."
sudo cp ../locale/locale.conf /etc/locale.conf
sudo locale-gen
localctl set-locale LANG=en_US.UTF8

echo "Install features"

echo "Vim..."
sudo pacman -S vim --noconfirm --needed
echo "Xorg..."
sudo pacman -S xorg-server xorg-apps xorg-xinit --noconfirm --needed
echo "I3 gaps..."
yaourt -S i3-gaps compton polybar-git rofi feh --noconfirm --needed
echo "Fonts..."
yaourt -S monaco-powerline-font-git otf-font-awesome noto-fonts noto-fonts-emoji noto-fonts-extra ttf-material-design-icons ttf-unifont --noconfirm --needed
echo "Chrome..."
yaourt -S ttf-croscore google-chrome
echo "Visual studio code..."
yaourt -S visual-studio-code-insiders x11-ssh-askpass
code --install-extension Shan.code-settings-sync
