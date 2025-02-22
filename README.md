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

I use the following config files:

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
git clone https://github.com/rodneyosodo/dotfiles.git
cd dotfiles
bash install
```

## Run ansible playbooks

```bash
cd ansible
make setup-desktop
```

## After Installation

- Brave - Join the existing sync chain and let it sync your data.
- Login into your Google account.
- Login into vaultwarden
- Sync folders using syncthing

Change keybindings for flameshot to `Print` and `Ctrl + Print`

## Setup Dotfiles

```bash
cd config
make install-dotfiles
```
