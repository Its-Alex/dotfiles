#!/bin/sh

echo "====> Configure os..."

echo "==> Locale..."
sudo cp ../locale/locale.gen /etc/locale.gen
sudo locale-gen
localectl set-locale LANG=en_US.UTF8
echo "==> Sound (pulseaudio)..."
yay -S pulseaudio pulseaudio-alsa --noconfirm --needed

echo "===> Install features..."

echo "==> Vim..."
sudo pacman -S vim --noconfirm --needed
echo "==> I3 gaps..."
yay -R i3blocks i3status i3-wm
yay -S i3-gaps compton polybar-git rofi feh unclutter --noconfirm --needed
echo "==> Fonts..."
yay -S monaco-powerline-font-git otf-font-awesome noto-fonts noto-fonts-emoji noto-fonts-extra ttf-material-design-icons ttf-unifont ttf-droid --noconfirm --needed
echo "==> Chrome..."
yay -S ttf-croscore google-chrome --noconfirm --needed
echo "==> Visual studio code..."
yay -S visual-studio-code-bin --noconfirm --needed
code --user-data-dir "${HOME}" --install-extension Shan.code-settings-sync
echo "==> Terminator..."
yay -S terminator --noconfirm --needed
# echo "==> Keyrings..."
# yay -S gnome-keyring --noconfirm --needed
echo "==> Docker..."
yay -S docker docker-compose --noconfirm --needed
sudo usermod -aG docker "${USER}"
systemctl enable docker
echo "==> Virtualbox..."
yay -S virtualbox virtualbox-host-dkms linux-headers --noconfirm --needed
echo "==> Vagrant..."
yay -S vagrant --noconfirm --needed
echo "==> Spotify..."
yay -S spotify --noconfirm --needed

echo "==> Grub update..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "==> Theme..."
yay -S lxappearance adapta-gtk-theme --noconfirm --needed
echo "==> Construct home..."
mkdir -p ~/Documents
mkdir -p ~/Downloads
cp -R ../Pictures ~/

yay -S zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
