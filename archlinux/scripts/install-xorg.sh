#!/bin/sh

echo "Install vim..."
sudo pacman -S vim --noconfirm --needed
echo "Install xorg..."
sudo pacman -S xorg-server xorg-apps xorg-xinit --noconfirm --needed
echo "Install i3..."
yaourt -S i3-gaps compton polybar-git rofi feh --noconfirm --needed
echo "Install fonts..."
yaourt -S monaco-powerline-font-git otf-font-awesome --noconfirm --needed 
