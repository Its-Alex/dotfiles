#!/bin/sh

echo "Configure os..."

echo "Locale..."
sudo cp ../locale/locale.conf /etc/locale.conf
sudo locale-gen
localctl set-locale LANG=en_US.UTF8
echo "Sound (pulseaudio)..."
yaourt -S pulseaudio pulseaudio-alsa pulseaudio-alsa 

echo "Install features..."

echo "Vim..."
sudo pacman -S vim --noconfirm --needed
echo "Xorg..."
sudo pacman -S xorg-server xorg-apps xorg-xinit --noconfirm --needed
echo "I3 gaps..."
yaourt -S i3-gaps compton polybar-git rofi feh --noconfirm --needed
echo "Fonts..."
yaourt -S monaco-powerline-font-git otf-font-awesome noto-fonts noto-fonts-emoji noto-fonts-extra ttf-material-design-icons ttf-unifont --noconfirm --needed
echo "Chrome..."
yaourt -S ttf-croscore google-chrome --noconfirm --needed
echo "Visual studio code..."
yaourt -S visual-studio-code --noconfirm --needed
code --install-extension Shan.code-settings-sync
echo "Terminator..."
yaourt -S terminator --noconfirm --needed
echo "Keyrings..."
yaourt -S gnome-keyring --noconfirm --needed
echo "Docker..."
yaourt -S docker docker-compose --noconfirm --needed
sudo usermod -aG docker $USER
systemctl enable docker
echo "Virtualbox..."
yaourt -S virtualbox virtualbox-host-dkms linux-headers --noconfirm --needed
echo "Vagrant..."
yaourt -S vagrant --noconfirm --needed
