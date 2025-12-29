# Marchintosh

A customized Arch Linux live ISO with KDE Plasma, pre-configured with themes, settings, and applications for a macOS-like experience on Arch Linux.

## Features

- **Desktop Environment**: KDE Plasma on Wayland
- **Display Manager**: SDDM
- **Pre-configured Settings**: Custom themes, fonts, animations, and window effects
- **66+ Packages**: Includes development tools, multimedia apps, and system utilities
- **Hardware Support**: NVIDIA drivers, AMD microcode, Bluetooth, and NetworkManager
- **Easy Installation**: One-command installer script included

## Download

Download all ISO parts from [Releases](https://github.com/Sourodyuti/marchintosh/releases):
- `archintosh-part-aa`
- `archintosh-part-ab`
- (and any other parts)

### Merge ISO Parts

After downloading all parts to the same directory:

**Linux/macOS:**
```
cat archintosh-part-* > archintosh.iso
```

**Windows (PowerShell):**
```
Get-Content archintosh-part-* -Raw | Set-Content archintosh.iso -Encoding Byte
```

**Windows (Command Prompt):**
```
copy /b archintosh-part-aa+archintosh-part-ab archintosh.iso
```

Verify the merged ISO (optional):
```
sha256sum archintosh.iso
```

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

## Installation

### 1. Write ISO to USB Drive

**Linux:**
```
sudo dd if=archintosh.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

**Windows:** Use [Rufus](https://rufus.ie/) or [Etcher](https://etcher.balena.io/)

**macOS:**
```
sudo dd if=archintosh.iso of=/dev/diskX bs=4m
```

### 2. Boot from USB
- Insert the USB drive
- Restart and select USB drive from boot menu (usually F12, F2, or Del)

### 3. Install to Hard Drive
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

### 4. Post-Installation
After rebooting into the installed system:

Install AUR packages (as your regular user, NOT root):
```
/root/install_aur_packages.sh
```

## Testing in QEMU

```
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 4 \
  -cdrom archintosh.iso \
  -boot d \
  -device virtio-vga \
  -display gtk
```

## Building from Source

### Prerequisites
```
sudo pacman -S archiso git rsync
```

### Build Process
```
git clone https://github.com/Sourodyuti/marchintosh
cd marchintosh
sudo mkarchiso -v -w work -o out iso
```

The ISO will be created in the `out/` directory (~2.1GB).

## Project Structure

```
marchintosh/
├── iso/
│   ├── airootfs/           # Root filesystem overlay
│   │   ├── etc/            # System configuration
│   │   │   └── skel/       # User skeleton (configs for new users)
│   │   └── root/           # Root user configs
│   │       ├── install.sh              # Installation script
│   │       ├── install_aur_packages.sh # AUR package installer
│   │       └── AUR_PACKAGES_README.txt # List of AUR packages
│   ├── grub/               # GRUB bootloader configuration
│   ├── syslinux/           # Syslinux bootloader configuration
│   ├── packages.x86_64     # Package list
│   ├── pacman.conf         # Pacman configuration
│   └── profiledef.sh       # ISO build profile
└── scripts/                # Post-install customization scripts
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