# Installation

I use `archinstall` to install Arch Linux. After booting into Arch connect to the internet using `iwctl` and then run the following command:

```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect <SSID>
ping rodneyosodo.com
```

I will in the future provide config files for my Arch Linux setup so that you can replicate it by running

```bash
archinstall --config <path to user config file or URL> --creds <path to user credentials config file or URL>
```

For now, you can use the following config files:

```json
{
  "additional-repositories": ["multilib"],
  "archinstall-language": "English",
  "audio": "", // Left and install pulseaudio and pavucontrol after.
  "bootloader": "Grub",
  "filesystem": "btrfs", // Use best effort partition layout. Subvolumes yes, compression no.
  "gfx_driver": "VMware / VirtualBox (open-source)",
  "harddrives": [
    "/dev/nvme0n1" //
  ],
  "hostname": "rodneypc", // Change this to your hostname
  "kernels": ["linux"],
  "keyboard-language": "us",
  "mirror-region": "", // Left blank to use the fastest mirror.
  "nic": {
    "NetworkManager": true,
    "nic": "Use NetworkManager (necessary to configure internet graphically in GNOME and KDE)"
  },
  "ntp": true,
  "profile": "gnome", // Grapphics driver AMD / ATI (open-source)
  "sys-encoding": "utf-8",
  "sys-language": "en_GB",
  "swap": true,
  "timezone": "Africa/Nairobi"
}
```

## Update the system

```bash
sudo pacman -Syu
```

## Install AMD Microcode

```bash
yay -S amd-ucode
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Edit Pacman Conf

```bash
sudo vim /etc/pacman.conf
```

The changes should reflect [pacman.conf](arch/pacman.conf)

## Edit Environment

```bash
sudo vim /etc/environment
```

The changes should reflect [environment](arch/environment)

## Install yay

```bash
sudo pacman -Sy --needed git base-devel
cd Downloads/
git clone https://aur.archlinux.org/yay.git
cd yay/
makepkg -si
```

## Install Brave

```bash
yay -S brave-bin
```

Join the existing sync chain. Then log in to your Google account.

## Install VSCode

```bash
yay -S visual-studio-code-bin
```

Setup system settings sync to install extensions and settings.

## Install Utilities

```bash
yay -S git vim neofetch p7zip unrar tar flac curl wget make jdk-openjdk thefuck wakatime  python-pip
```

## Bluetooth

```bash
yay -S bluez blueman bluez-utils
sudo modprobe btusb
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

## Audio

```bash
yay -S pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-jack pavucontrol alsa alsa-mixer
```

## Setup Git

```bash
ssh-keygen -t ed25519 -C "socials@rodneyosodo.com" -f ~/.ssh/github
ssh -T git@github.com
git config --global user.email "socials@rodneyosodo.com"
git config --global user.name "Rodney Osodo"
```

Copy the contents of `~/.ssh/github.pub` to github both for authentication and signing keys.

## Install oh-my-zsh

```bash
yay -S zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Install dotfiles

```bash
git clone git@github.com:rodneyosodo/dotfiles.git
cd dotfiles/
```

## Edit Zshrc

```bash
vim ~/.zshrc
```

The changes should reflect [zshrc](zsh/zshrc)

### Install Jovial Theme

```bash
curl -sSL https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo -E bash -s ${USER:=`whoami`}
```

### Install autojump

```bash
cd Downloads/
git clone https://github.com/wting/autojump.git
cd autojump/
./install.py
```

### Install ZSH Wakatime

```bash
cd ~/.oh-my-zsh/custom/plugins && git clone https://github.com/wbingli/zsh-wakatime.git
git clone git@github.com:irondoge/bash-wakatime.git .wakatime/bash-wakatime
```

## Install bpytop

```bash
pip install bpytop --break-system-packages
```

## Install major software

```bash
yay -S slack-desktop teams discord easyeda kicad obsidian libreoffice obs-studio vlc postman inkscape gimp virtualbox virt-manager flameshot diodon
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER // Logout and login again
sudo systemctl restart libvirtd.service
```

Change keybindings for flameshot to `Print` and `Ctrl + Print`

## Install

```bash
yay -S go mosquitto-clients minikube kubectl rustup act-bin github-cli httpie putty neovim docker docker-compose tilix rancher-k3d-bin bandwhich vagrant hyperfine helm nomad
gh auth login
rustup toolchain install nightly
rustup default nightly
rustup component add cargo
rustup component add rust-src
rustup component add rust-analyzer
rustup component add rustfmt
rustup component add clippy
rustup component add rust-docs
rustup component add rust-std
rustup component add rustc
rustup component add rustc-dev
rustup component add llvm-tools-preview
minikube config set cpus 4
minikube config set memory 8192
minikube addons enable dashboard
minikube addons enable headlamp
minikube addons enable helm-tiller
minikube addons enable ingress
minikube addons enable ingress-dns
minikube addons enable istio
minikube addons enable kong
minikube addons enable metallb
minikube addons enable logviewer
minikube addons enable metrics-server
minikube addons enable registry
minikube cache add kibana/kibana:5.6.2-custom
vagrant plugin install vagrant-qemu
vagrant plugin install vagrant-share
vagrant box add hashicorp/bionic64
vagrant autocomplete install
vagrant box add bento/ubuntu-22.04
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ory https://k8s.ory.sh/helm/charts
```

## Themeing

### Extensions

```bash
yay -S gnome-tweaks gnome-browser-connector
```

- Extension Manager - <https://extensions.gnome.org/>
- Blur My Shell - <https://extensions.gnome.org/extension/3193/blur-my-shell/>
- User Themes - <https://extensions.gnome.org/extension/19/user-themes/>
- Dash to Dock - <https://extensions.gnome.org/extension/307/dash-to-dock/>
- Window List - <https://extensions.gnome.org/extension/602/window-list/>
- Workspace Indicator - <https://extensions.gnome.org/extension/21/workspace-indicator/>
- Tray Icons: Reloaded - <https://extensions.gnome.org/extension/2890/tray-icons-reloaded/>
- Vitals - <https://extensions.gnome.org/extension/1460/vitals/>

### GTK

```bash
cd Downloads/
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme/
./install.sh
```

### Cursor

```bash
cd Downloads/
git clone https://github.com/vinceliuice/McMojave-cursors.git
cd McMojave-cursors/
./install.sh
```

### Icons

```bash
git clone git@github.com:USBA/Cupertino-Ventura-iCons.git ~/.icons/Cupertino-Ventura-iCons
```

### Notable mentions

1. <https://github.com/Fausto-Korpsvart/Material-GTK-Themes>
2. <https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme>

## Install AMD Drivers

```bash
yay -S mesa xf86-video-amdgpu vulkan-radeon vulkan-icd-loader libva-mesa-driver mesa-vdpau amdgpu_top-bin
```
