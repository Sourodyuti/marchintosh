# Archintosh Snapshot

A customized Arch Linux live ISO with KDE Plasma, pre-configured with themes, settings, and applications for a ready-to-use system.

## Features

- **Desktop Environment**: KDE Plasma on Wayland
- **Display Manager**: SDDM
- **Pre-configured Settings**: Custom themes, fonts, animations, and window effects
- **66+ Packages**: Includes development tools, multimedia apps, and system utilities
- **Hardware Support**: NVIDIA drivers, AMD microcode, Bluetooth, and NetworkManager
- **Easy Installation**: One-command installer script included

## What's Included

### System Packages
- Base system with latest kernel
- KDE Plasma desktop environment (plasma-meta)
- Essential applications: Dolphin, Konsole, Kate, Spectacle
- Development tools: Git, Vim, Base-devel
- Multimedia: PipeWire, Wireplumber
- Network: NetworkManager, Bluetooth stack
- Bootloader: GRUB with UEFI support

### Customizations
- Custom KDE themes and color schemes
- Configured animations and window effects
- Custom font configurations
- Plasma desktop layouts
- Application settings and profiles

### AUR Packages (Post-Install)
- Brave Browser
- Spotify
- Visual Studio Code
- Yay (AUR helper)

## Building the ISO

### Prerequisites
```
sudo pacman -S archiso git rsync
```

### Build Process
```
git clone https://github.com/Sourodyuti/archintosh-snapshot
cd archintosh-snapshot
sudo mkarchiso -v -w work -o out iso_profile
```

The ISO will be created in the `out/` directory.

## Installation

### Boot from ISO
1. Write the ISO to USB drive:
   ```
   sudo dd if=out/archintosh-*.iso of=/dev/sdX bs=4M status=progress
   ```
2. Boot from the USB drive

### Install to Hard Drive
1. Login as `root` (no password required)
2. Run the installer:
   ```
   /root/install.sh
   ```
3. Follow the prompts to:
   - Select target disk
   - Partition and format
   - Install base system and packages
   - Configure bootloader
   - Set root password
   - Create user account

### Post-Installation
After rebooting into the installed system:

1. Install AUR packages (as your regular user, NOT root):
   ```
   /root/install_aur_packages.sh
   ```

## Testing in QEMU

```
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 4 \
  -cdrom out/archintosh-*.iso \
  -boot d \
  -device virtio-vga \
  -display gtk
```

## Project Structure

```
archintosh-snapshot/
├── iso_profile/
│   ├── airootfs/           # Root filesystem overlay
│   │   ├── etc/            # System configuration
│   │   │   └── skel/       # User skeleton (configs for new users)
│   │   └── root/           # Root user configs
│   │       ├── install.sh              # Installation script
│   │       ├── install_aur_packages.sh # AUR package installer
│   │       └── aur_packages.txt        # List of AUR packages
│   ├── grub/               # GRUB bootloader configuration
│   ├── syslinux/           # Syslinux bootloader configuration
│   ├── packages.x86_64     # Package list
│   ├── pacman.conf         # Pacman configuration
│   └── profiledef.sh       # ISO build profile
└── system_info/            # System snapshot data
```

## Notes

- The ISO includes configurations but NOT personal files (Documents, Pictures, etc.)
- Browser data, Discord settings, and other app-specific data are not included
- AUR packages need to be installed manually after system installation
- Total ISO size: ~2.1 GB

## Hardware Requirements

- **RAM**: 2 GB minimum, 4 GB recommended
- **Storage**: 20 GB minimum
- **Architecture**: x86_64
- **Boot**: UEFI or Legacy BIOS supported

## Credits

Built with [archiso](https://wiki.archlinux.org/title/Archiso) - the official Arch Linux ISO building tool.

## License

This is a personal system snapshot. Package licenses apply from their respective upstream sources.