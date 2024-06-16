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

## Update the system

```bash
sudo pacman -Syu
```

## Install yay

```bash
sudo pacman -Sy --needed git base-devel
```

```bash
cd ~/Downloads/ && git clone https://aur.archlinux.org/yay.git --depth=1 && cd yay/ && makepkg -si && cd ~
```

## Install Utilities

```bash
yay -S git vim neovim neofetch p7zip unrar tar flac curl wget make jdk-openjdk thefuck wakatime python-pip bpytop alacritty httpie putty
```

## Install AMD Microcode

```bash
yay -S amd-ucode
```

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Bluetooth

```bash
yay -S bluez blueman bluez-utils
```

```bash
sudo modprobe btusb
```

```bash
sudo systemctl start bluetooth
```

```bash
sudo systemctl enable bluetooth
```

## Audio

```bash
yay -S pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-jack pavucontrol
```

## Preload

```bash
yay -S preload
```

```bash
sudo systemctl start preload.service
```

```bash
sudo systemctl enable preload.service
```

## Pacman Cache

```bash
yay -S pacman-contrib
```

```bash
sudo systemctl start paccache.timer
```

```bash
sudo systemctl enable paccache.timer
```

## Install major software

```bash
yay -S brave-bin slack-desktop discord easyeda kicad obsidian obs-studio vlc postman-bin inkscape gimp dnsmasq virt-manager qemu-full flameshot
```

For brave, join the existing sync chain. Then log in to your Google account.

Change keybindings for flameshot to `Print` and `Ctrl + Print`

## Setup Git

```bash
ssh-keygen -t ed25519 -C "socials@rodneyosodo.com" -f ~/.ssh/github
```

```bash
git config --global user.email "socials@rodneyosodo.com"
```

```bash
git config --global user.name "Rodney Osodo"
```

```bash
git config --global user.signingkey ~/.ssh/github
```

Copy the contents of `~/.ssh/github.pub` to github both for authentication and signing keys.

## Install oh-my-zsh

```bash
yay -S zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
cd ~/Downloads/ && git clone https://github.com/wting/autojump.git --depth=1 && cd autojump/ && ./install.py && cd ~
```

### Install ZSH Wakatime

```bash
cd ~/.oh-my-zsh/custom/plugins && git clone https://github.com/wbingli/zsh-wakatime.git --depth=1 && git clone https://github.com/irondoge/bash-wakatime.git --depth=1 && cd ~
```

## Install

```bash
yay -S go nodejs zig bun-bin mosquitto-clients kubectl rustup act github-cli docker docker-compose docker-buildx vagrant hyperfine helm nomad dbeaver visual-studio-code-bin
```

```bash
sudo systemctl start docker
```

```bash
sudo systemctl enable docker
```

```bash
sudo usermod -aG docker $USER
```

```bash
sudo systemctl restart libvirtd.service

gh auth login

rustup toolchain install nightly
rustup default nightly
rustup component add llvm-tools-preview

vagrant box add hashicorp/bionic64
vagrant box add bento/ubuntu-24.04
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
- Clipboard Indicator - <https://extensions.gnome.org/extension/779/clipboard-indicator/>
- Compiz windows effect - <https://extensions.gnome.org/extension/3210/compiz-windows-effect/>
- User Themes - <https://extensions.gnome.org/extension/19/user-themes/>
- Dash to Dock - <https://extensions.gnome.org/extension/307/dash-to-dock/>
- Window List - <https://extensions.gnome.org/extension/602/window-list/>
- Workspace Indicator - <https://extensions.gnome.org/extension/21/workspace-indicator/>
- Tray Icons: Reloaded - <https://extensions.gnome.org/extension/2890/tray-icons-reloaded/>
- Vitals - <https://extensions.gnome.org/extension/1460/vitals/>
- Just Perfection - <https://extensions.gnome.org/extension/3843/just-perfection/>
- Logo Menu - <https://extensions.gnome.org/extension/4451/logo-menu/>
- Quick Setting Tweaker - <https://extensions.gnome.org/extension/5446/quick-settings-tweaker/>
- Tiling Assistant - <https://extensions.gnome.org/extension/3733/tiling-assistant/>
- User Avatar In Quick Settings - <https://extensions.gnome.org/extension/5506/user-avatar-in-quick-settings/>

### GTK

```bash
yay -S gtk-engine-murrine sassc ttf-hack-nerd
```

Applying themes to Flatpak applications

```bash
sudo flatpak override --filesystem=$HOME/.themes
sudo flatpak override --filesystem=$HOME/.icons
flatpak override --user --filesystem=xdg-config/gtk-4.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0
```

```bash
cd ~/Downloads/ && git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1 && cd WhiteSur-gtk-theme/ && ./install.sh && cd ~
```

```bash
cd ~/Downloads/ && git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git --depth=1 && cd Gruvbox-GTK-Theme/ && ./install.sh -l && cd ~
```

### Cursor

```bash
cd ~/Downloads/ && git clone https://github.com/vinceliuice/McMojave-cursors.git --depth=1 && cd McMojave-cursors/ && ./install.sh && cd ~
```

### Icons

```bash
git clone https://github.com/USBA/Cupertino-Ventura-iCons.git --depth=1 ~/.icons/Cupertino-Ventura-iCons
```

## Install AMD Drivers

```bash
yay -S mesa xf86-video-amdgpu vulkan-radeon vulkan-icd-loader libva-mesa-driver mesa-vdpau amdgpu_top-bin
```
