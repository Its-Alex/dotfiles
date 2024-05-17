#!/bin/sh

printf "\e[1;34m%s\e[1;0m\n" "Configure os..."

printf "\e[1;34m%s\e[1;0m\n" "Install Git..."
sudo pacman -S git base-devel
cp ../files/.gitconfig "${HOME}/.gitconfig"
printf "\e[1;34m%s\e[1;0m\n" "Install Yay..."
git clone https://aur.archlinux.org/yay.git /tmp/yay
(
    cd /tmp/yay || exit 1
    makepkg -si
)
rm -rf /tmp/yay

printf "\e[1;34m%s\e[1;0m\n" "Install needed programs.."
yay -S --noconfirm --needed xkb-qwerty-fr \
    vim \
    otf-font-awesome noto-fonts noto-fonts-emoji noto-fonts-extra ttf-material-design-icons ttf-unifont ttf-droid ttf-fira-code \
    alacritty tmux tmuxinator \
    gnome-keyring \
    docker \
    virtualbox virtualbox-host-dkms linux-headers \
    vagrant \
    zsh \
    jq \
    flatpak

printf "\e[1;34m%s\e[1;0m\n" "Install custom programs.."
yay -S --noconfirm --needed \
    numix-cursor-theme numix-frost-themes numix-square-icon-theme flat-remix-gnome \
    unzip \
    tar \
    fzf

flatpak -y install flathub org.mozilla.firefox \
    com.google.Chrome \
    org.signal.Signal \
    com.slack.Slack \
    com.discordapp.Discord \
    com.spotify.Client \
    net.cozic.joplin_desktop \
    im.riot.Riot \
    com.visualstudio.code \
    com.authy.Authy \
    org.videolan.VLC

printf "\e[1;34m%s\e[1;0m\n" "Setup programs.."
# Setup tmux
mkdir -p "${HOME}/.tmux/plugins"
git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
# Setup docker
sudo usermod -aG docker "${USER}"
sudo systemctl enable docker
# Setup grub for Windows boot
echo "==> Grub update for Microsoft boot..."
sudo grub-mkconfig -o /boot/grub/grub.cfg
# Setup ohmyzsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Install https://github.com/jdx/mise
curl https://mise.jdx.dev/mise-latest-linux-x64 > /tmp/mise
sudo mv /tmp/mise /usr/local/bin

# Nvidia
# yay -S --noconfirm --needed \
#     nvidia \
#     nvidia-dkms \
#     nvidia-settings \
#     nvidia-utils
