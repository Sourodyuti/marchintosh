# Marchintosh

A customized Arch Linux live ISO with KDE Plasma, pre-configured with themes, fonts, and applications for a polished desktop experience out of the box.

## Features

- **Desktop Environment**: KDE Plasma on Wayland with custom themes and animations
- **Display Manager**: SDDM — boots directly into a graphical login screen
- **Shell**: Zsh with Starship prompt, autosuggestions, and syntax highlighting
- **70+ Packages**: Development tools, multimedia, system utilities, and more
- **Hardware Support**: Intel/AMD microcode, NVIDIA drivers, Bluetooth, NetworkManager
- **One-Command Installer**: Guided script handles partitioning, bootloader, user creation, and configuration
 
## Table of Contents

- [Download](#download)
- [Installation Guide](#installation-guide)
  - [Step 1 — Prepare the ISO](#step-1--prepare-the-iso)
  - [Step 2 — Create a bootable USB](#step-2--create-a-bootable-usb)
  - [Step 3 — Boot from USB](#step-3--boot-from-usb)
  - [Step 4 — Connect to the internet](#step-4--connect-to-the-internet)
  - [Step 5 — Run the installer](#step-5--run-the-installer)
  - [Step 6 — Post-installation](#step-6--post-installation)
- [Testing in QEMU](#testing-in-qemu)
- [Building from Source](#building-from-source)
- [What's Included](#whats-included)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Hardware Requirements](#hardware-requirements)
- [Contributing](#contributing)
- [License](#license)

---

## Download

Download all ISO parts from [Releases](https://github.com/Sourodyuti/marchintosh/releases):
- `archintosh-part-aa`
- `archintosh-part-ab`
- (and any additional parts)

---

## Installation Guide

### Step 1 — Prepare the ISO

After downloading all parts to the same directory, merge them into a single ISO file.

**Linux / macOS:**
```bash
cat archintosh-part-* > archintosh.iso
```

**Windows (PowerShell):**
```powershell
Get-Content archintosh-part-* -Raw | Set-Content archintosh.iso -Encoding Byte
```

**Windows (Command Prompt):**
```cmd
copy /b archintosh-part-aa+archintosh-part-ab archintosh.iso
```

**Verify the ISO (optional):**
```bash
sha256sum archintosh.iso
```
Compare the hash against the one listed in the release notes.

---

### Step 2 — Create a bootable USB

You need a USB drive with at least **4 GB** of free space. All data on the USB will be erased.

**Linux:**
```bash
# Replace /dev/sdX with your USB device (use lsblk to identify it)
sudo dd if=archintosh.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

**Windows:** Use [Rufus](https://rufus.ie/) (recommended) or [balenaEtcher](https://etcher.balena.io/)
- In Rufus: select the ISO, choose **DD Image** mode if prompted, and click Start.

**macOS:**
```bash
# Replace /dev/diskX with your USB device (use diskutil list to identify)
sudo dd if=archintosh.iso of=/dev/diskX bs=4m
```

> [!CAUTION]
> Double-check the target device. Writing to the wrong disk will destroy its data.

---

### Step 3 — Boot from USB

1. Insert the USB drive into the target computer.
2. Restart and enter the boot menu (commonly **F12**, **F2**, **Del**, or **Esc** — depends on your motherboard).
3. Select the USB drive from the boot menu.
4. Choose **"Arch Linux install medium"** from the GRUB menu.
5. The system will boot into the KDE Plasma desktop via SDDM automatically.

> [!TIP]
> If you see a command-line login instead of the desktop, type `systemctl start sddm` and press Enter.

---

### Step 4 — Connect to the internet

The installer requires an active internet connection.

**Ethernet:** Should connect automatically via DHCP. Verify with:
```bash
ping -c 3 archlinux.org
```

**Wi-Fi:** Open a terminal (Konsole) and use `nmcli`:
```bash
# List available networks
nmcli device wifi list

# Connect to a network
nmcli device wifi connect "YourNetworkName" password "YourPassword"

# Verify connection
ping -c 3 archlinux.org
```

---

### Step 5 — Run the installer

Open a terminal and run:

```bash
/root/install.sh
```

The installer will guide you through the following steps:

| Step | What happens | Your input |
|------|-------------|------------|
| 1 | Lists available disks | Type the disk name (e.g., `sda` or `nvme0n1`) |
| 2 | Confirmation prompt | Type `YES` to confirm (this erases the disk) |
| 3 | Partitioning | Automatic — creates a 512MB EFI partition + root partition |
| 4 | Formatting | Automatic — FAT32 for EFI, ext4 for root |
| 5 | Package installation | Automatic — installs all packages from the live ISO |
| 6 | Swap setup | Automatic — creates a 4GB swapfile |
| 7 | System config | Automatic — timezone, locale, hostname, hosts, services |
| 8 | Bootloader | Automatic — installs GRUB for UEFI |
| 9 | Root password | Enter and confirm a root password |
| 10 | User creation | Enter your username, then set and confirm your password |
| 11 | Config copy | Automatic — copies KDE themes and shell configs to your home |

> [!IMPORTANT]
> The script automatically detects your CPU (Intel or AMD) and installs the correct microcode package. NVIDIA drivers from the live ISO are intentionally excluded to avoid issues on non-NVIDIA systems.

After the script completes:

```bash
umount -R /mnt
reboot
```

Remove the USB drive when prompted.

---

### Step 6 — Post-installation

After rebooting, you'll see the SDDM login screen. Log in with the username and password you set during installation.

#### Install AUR packages

A helper script is in your home directory:

```bash
cd ~
./install_aur_packages.sh
```

This installs:
- **yay** — AUR helper
- **Brave Browser**
- **Spotify**
- **Visual Studio Code**

> [!WARNING]
> Do **not** run the AUR script as root. Run it as your regular user.

#### First-boot checklist

- [ ] Verify Wi-Fi / Ethernet is connected
- [ ] Check that KDE Plasma desktop loads correctly
- [ ] Run `sudo pacman -Syu` to update the system
- [ ] Install AUR packages with `~/install_aur_packages.sh`
- [ ] Set your preferred wallpaper and theme in **System Settings → Appearance**

---

## Testing in QEMU

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 4 \
  -cdrom archintosh.iso \
  -boot d \
  -device virtio-vga \
  -display gtk
```

The live ISO should boot directly into the SDDM login screen. Log in as `root` (no password).

---

## Building from Source

### Prerequisites
```bash
sudo pacman -S archiso git rsync
```

### Build
```bash
git clone https://github.com/Sourodyuti/marchintosh
cd marchintosh
sudo mkarchiso -v -w work -o out iso_profile
```

The ISO will be created in the `out/` directory (~2.1 GB).

### Clean build artifacts
```bash
sudo rm -rf work
```

---

## What's Included

### System Packages
| Category | Packages |
|----------|----------|
| **Base** | `base`, `linux`, `linux-firmware`, `base-devel`, `sudo` |
| **Desktop** | `plasma-desktop`, `sddm`, `kscreen`, `powerdevil`, `kvantum` |
| **Apps** | `dolphin`, `konsole`, `kate`, `spectacle` |
| **Multimedia** | `pipewire`, `pipewire-pulse`, `pipewire-jack`, `wireplumber` |
| **Network** | `networkmanager`, `bluez`, `bluez-utils` |
| **Bootloader** | `grub`, `efibootmgr`, `os-prober` |
| **Shell** | `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `starship` |
| **Fonts** | `inter-font`, `ttf-fira-code`, `ttf-jetbrains-mono-nerd` |
| **Drivers** | `nvidia-open`, `nvidia-utils`, `amd-ucode`, `intel-ucode` |
| **Virtualization** | `qemu-full`, `virt-manager`, `virt-viewer` |

### Customizations
- Custom KDE Plasma themes and color schemes
- Preconfigured window animations and effects
- Zsh with Starship prompt, autosuggestions, and syntax highlighting
- Papirus icon theme
- Custom font configurations

### AUR Packages (post-install)
- Brave Browser
- Spotify
- Visual Studio Code
- yay (AUR helper)

---

## Project Structure

```
marchintosh/
├── iso_profile/
│   ├── airootfs/                    # Root filesystem overlay
│   │   ├── etc/
│   │   │   ├── skel/               # User skeleton (configs for new users)
│   │   │   │   ├── .config/        # KDE Plasma, Kvantum, etc.
│   │   │   │   ├── .local/         # Local share data
│   │   │   │   └── .zshrc          # Zsh configuration
│   │   │   ├── systemd/system/
│   │   │   │   └── default.target  # → graphical.target (auto-start GUI)
│   │   │   ├── hostname
│   │   │   ├── locale.conf
│   │   │   └── passwd
│   │   ├── root/
│   │   │   ├── install.sh              # Main installation script
│   │   │   ├── install_aur_packages.sh # AUR package installer
│   │   │   ├── AUR_PACKAGES_README.txt # AUR package reference
│   │   │   └── aur_packages.txt        # AUR package list
│   │   └── usr/share/fonts/custom/     # Bundled fonts
│   ├── grub/                       # GRUB bootloader config
│   ├── syslinux/                   # Syslinux bootloader config
│   ├── efiboot/                    # EFI boot config
│   ├── packages.x86_64            # Official package list
│   ├── pacman.conf                # Pacman configuration
│   ├── profiledef.sh              # ISO build profile
│   └── bootstrap_packages        # Bootstrap packages
├── system_snapshot.sh             # System info collection utility
├── .gitignore
└── README.md
```

---

## Troubleshooting

### Live ISO boots to a black screen or TTY
Open a terminal or switch to a TTY (Ctrl+Alt+F2) and run:
```bash
systemctl start sddm
```

### Installer fails with "Disk not found"
Make sure you're entering only the disk name, not the full path:
- ✅ `sda`
- ✅ `nvme0n1`
- ❌ `/dev/sda`

### No internet connection
```bash
# Check network interfaces
ip link show

# Restart NetworkManager
systemctl restart NetworkManager

# For Wi-Fi
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"
```

### GRUB doesn't appear after installation
Boot from the USB again and reinstall GRUB:
```bash
mount /dev/sdX2 /mnt
mount /dev/sdX1 /mnt/boot
arch-chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
exit
umount -R /mnt
reboot
```

### AUR script fails with "Do not run as root"
Run it as your normal user, not with `sudo`:
```bash
./install_aur_packages.sh
```

---

## Hardware Requirements

| Requirement | Minimum | Recommended |
|------------|---------|-------------|
| **RAM** | 2 GB | 4 GB+ |
| **Storage** | 20 GB | 40 GB+ |
| **Architecture** | x86_64 | x86_64 |
| **Boot** | UEFI | UEFI |
| **USB** | 4 GB | 8 GB+ |

> [!NOTE]
> Legacy BIOS boot is supported for the live ISO but the installer creates only UEFI (GPT) partitions. For Legacy BIOS installations, manual partitioning is required.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-change`)
3. Make your changes
4. Test by building the ISO locally with `mkarchiso`
5. Submit a pull request

---

## Credits

Built with [archiso](https://wiki.archlinux.org/title/Archiso) — the official Arch Linux ISO building tool.

## License

This is a personal system snapshot. Package licenses apply from their respective upstream sources.
