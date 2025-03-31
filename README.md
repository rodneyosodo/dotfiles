# Installation

```bash
# writing an ISO image to a USB stick using the dd command
sudo dd if=archlinux-x86_64.iso of=/dev/sdc bs=1M conv=sync status=progress
```

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
  "audio_config": {
    "audio": "pulseaudio"
  },
  "bootloader": "Grub",
  "config_version": "3.0.2",
  "disk_config": {
    "config_type": "default_layout",
    "device_modifications": [
      {
        "device": "/dev/nvme0n1",
        "partitions": [
          {
            "btrfs": [],
            "dev_path": null,
            "flags": ["boot", "esp"],
            "fs_type": "fat32",
            "mount_options": [],
            "mountpoint": "/boot",
            "obj_id": "126ab499-7169-45d7-96e7-880eec8c3e5a",
            "size": {
              "sector_size": {
                "unit": "B",
                "value": 512
              },
              "unit": "GiB",
              "value": 1
            },
            "start": {
              "sector_size": {
                "unit": "B",
                "value": 512
              },
              "unit": "MiB",
              "value": 1
            },
            "status": "create",
            "type": "primary"
          },
          {
            "btrfs": [
              {
                "mountpoint": "/",
                "name": "@"
              },
              {
                "mountpoint": "/home",
                "name": "@home"
              },
              {
                "mountpoint": "/var/log",
                "name": "@log"
              },
              {
                "mountpoint": "/var/cache/pacman/pkg",
                "name": "@pkg"
              },
              {
                "mountpoint": "/.snapshots",
                "name": "@.snapshots"
              }
            ],
            "dev_path": null,
            "flags": [],
            "fs_type": "btrfs",
            "mount_options": ["compress=zstd"],
            "mountpoint": null,
            "obj_id": "be1b2e7a-abf8-4efb-9625-17356b9992c6",
            "size": {
              "sector_size": {
                "unit": "B",
                "value": 512
              },
              "unit": "B",
              "value": 511035047936
            },
            "start": {
              "sector_size": {
                "unit": "B",
                "value": 512
              },
              "unit": "B",
              "value": 1074790400
            },
            "status": "create",
            "type": "primary"
          }
        ],
        "wipe": true
      }
    ]
  },
  "disk_encryption": {
    "encryption_type": "luks",
    "lvm_volumes": [],
    "partitions": ["be1b2e7a-abf8-4efb-9625-17356b9992c6"]
  },
  "hostname": "elgon",
  "kernels": ["linux", "linux-lts"],
  "locale_config": {
    "kb_layout": "us",
    "sys_enc": "UTF-8",
    "sys_lang": "en_GB"
  },
  "mirror_config": {
    "custom_mirrors": [],
    "mirror_regions": {}
  },
  "network_config": {
    "type": "nm"
  },
  "ntp": true,
  "packages": ["git"],
  "parallel downloads": 0,
  "profile_config": {
    "gfx_driver": "AMD / ATI (open-source)",
    "greeter": "sddm",
    "profile": {
      "custom_settings": {
        "GNOME": {},
        "Hyprland": {
          "seat_access": "polkit"
        }
      },
      "details": ["GNOME", "Hyprland"],
      "main": "Desktop"
    }
  },
  "save_config": null,
  "swap": true,
  "timezone": "Africa/Nairobi",
  "uki": false,
  "version": "3.0.2"
}
```

## Connect to Network

```bash
nmtui
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
make install-stow
make install-dotfiles
```

## Change Shell

```bash
sudo chsh --shell $(which zsh) $USER
```

## Login to Tailscale

```bash
sudo tailscale up --ssh
```

## Login to atuin

```bash
atuin login
atuin sync
```
