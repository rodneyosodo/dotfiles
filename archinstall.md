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

## Install Ansible

```bash
bash install
```

## Run ansible playbooks

```bash
cd ansible
make setup-desktop
```

## Install major software

For brave, join the existing sync chain. Then log in to your Google account.

Change keybindings for flameshot to `Print` and `Ctrl + Print`

## Sync Folders using Syncthing

## Setup Git

```bash
ssh-keygen -t ed25519 -C "socials@rodneyosodo.com" -f ~/.ssh/github
git config --global user.email "socials@rodneyosodo.com"
git config --global user.name "Rodney Osodo"
git config --global user.signingkey ~/.ssh/github
```

Copy the contents of `~/.ssh/github.pub` to github both for authentication and signing keys.

## Install

```bash
gh auth login
```
