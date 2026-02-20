#!/bin/bash
set -euo pipefail

# ============================================================
#  Archintosh Installation Script
#  Installs Arch Linux with KDE Plasma from the live ISO
# ============================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/root/install.log"

# --- Logging ---
# Log everything to file, but keep interactive prompts on the real terminal.
# File descriptor 3 = real terminal for interactive use.
exec 3>&1
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() { echo "❌ $*" >&2; exit 1; }

echo "================================================"
echo "  Archintosh Installation Script"
echo "================================================"
echo ""

# --- Cleanup trap ---
INSTALL_SUCCESS=false

cleanup() {
    if [ "$INSTALL_SUCCESS" = false ]; then
        echo ""
        echo "⚠️  Installation interrupted or failed. Cleaning up..."
        umount -R /mnt 2>/dev/null || true
        echo "📄 See $LOG_FILE for details."
    fi
}
trap cleanup EXIT
trap 'exit 1' INT TERM

# --- Root check ---
if [ "$EUID" -ne 0 ]; then
    die "Please run as root: sudo ./$SCRIPT_NAME"
fi

# --- Disk selection ---
log "Listing available disks..."
echo "Available disks:"
lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
echo ""
read -r -p "Enter target disk (e.g., sda, nvme0n1): " DISK <&3

# Validate: strip /dev/ prefix if user included it
DISK="${DISK#/dev/}"

# Validate: must be alphanumeric (with optional digits for nvme0n1, mmcblk0)
if [[ ! "$DISK" =~ ^[a-zA-Z0-9]+$ ]]; then
    die "Invalid disk name: '$DISK'. Use only alphanumeric characters."
fi

if [ ! -b "/dev/$DISK" ]; then
    die "Disk /dev/$DISK not found!"
fi

echo ""
echo "⚠️  WARNING: This will erase ALL data on /dev/$DISK"
read -r -p "Type 'YES' to continue: " CONFIRM <&3

if [ "$CONFIRM" != "YES" ]; then
    echo "Installation cancelled."
    exit 0
fi

# --- Partitioning ---
log "Partitioning /dev/$DISK..."
parted "/dev/$DISK" --script mklabel gpt
parted "/dev/$DISK" --script mkpart ESP fat32 1MiB 512MiB
parted "/dev/$DISK" --script set 1 esp on
parted "/dev/$DISK" --script mkpart primary ext4 512MiB 100%

# Wait for kernel to re-read partition table
sleep 1
partprobe "/dev/$DISK" 2>/dev/null || true
sleep 1

# Determine partition device names
if [[ "$DISK" == nvme* ]] || [[ "$DISK" == mmcblk* ]]; then
    PART1="${DISK}p1"
    PART2="${DISK}p2"
else
    PART1="${DISK}1"
    PART2="${DISK}2"
fi

# Verify partitions exist
[ -b "/dev/$PART1" ] || die "Partition /dev/$PART1 not found after partitioning!"
[ -b "/dev/$PART2" ] || die "Partition /dev/$PART2 not found after partitioning!"

log "Formatting partitions..."
mkfs.fat -F32 "/dev/$PART1"
mkfs.ext4 -F "/dev/$PART2"

log "Mounting filesystems..."
mount "/dev/$PART2" /mnt
mkdir -p /mnt/boot
mount "/dev/$PART1" /mnt/boot

# --- Package installation ---
log "Building package list from live ISO (filtering ISO-only packages)..."

# Packages that are only needed for the live ISO, not the installed system
ISO_ONLY_PKGS="archiso|mkinitcpio-archiso|mkinitcpio-nfs-utils|syslinux"
ISO_ONLY_PKGS+="|memtest86\\+|memtest86\\+-efi|edk2-ovmf|squashfs-tools"

# Get all installed packages, remove ISO-only ones
PACKAGES=$(pacman -Qq | grep -v -E "^(${ISO_ONLY_PKGS})$")

# Remove base/linux/linux-firmware from list since we specify them explicitly
PACKAGES=$(echo "$PACKAGES" | grep -v -E '^(base|linux|linux-firmware)$')

# Detect CPU vendor and add appropriate microcode
CPU_VENDOR=$(lscpu | grep "Vendor ID" | awk '{print $3}')
case "$CPU_VENDOR" in
    GenuineIntel) PACKAGES="$PACKAGES intel-ucode" ;;
    AuthenticAMD) PACKAGES="$PACKAGES amd-ucode" ;;
    *) log "Warning: Unknown CPU vendor '$CPU_VENDOR', skipping microcode." ;;
esac

log "Installing base system + $(echo "$PACKAGES" | wc -w) packages..."
# shellcheck disable=SC2086
pacstrap /mnt base linux linux-firmware $PACKAGES

# --- fstab ---
log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- Swapfile ---
log "Setting up 4G swapfile..."
arch-chroot /mnt fallocate -l 4G /swapfile
arch-chroot /mnt chmod 600 /swapfile
arch-chroot /mnt mkswap /swapfile
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

# --- Timezone selection ---
echo ""
echo "🌍 Timezone configuration"
LIVE_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "")
if [ -n "$LIVE_TZ" ]; then
    echo "Detected timezone: $LIVE_TZ"
    read -r -p "Use this timezone? [Y/n]: " TZ_CONFIRM <&3
    if [[ "$TZ_CONFIRM" =~ ^[Nn] ]]; then
        read -r -p "Enter timezone (e.g., America/New_York, Europe/London): " TIMEZONE <&3
    else
        TIMEZONE="$LIVE_TZ"
    fi
else
    read -r -p "Enter timezone (e.g., Asia/Kolkata, America/New_York): " TIMEZONE <&3
fi

# Validate timezone
if [ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
    echo "⚠️  Invalid timezone '$TIMEZONE', defaulting to UTC"
    TIMEZONE="UTC"
fi

# --- System configuration (non-interactive heredoc) ---
log "Configuring system (timezone, locale, hostname, services, bootloader)..."
arch-chroot /mnt /bin/bash <<CHROOT_EOF
# Set timezone
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Set locale (uncomment rather than append to avoid duplicates)
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "archintosh" > /etc/hostname

# Set hosts file
cat > /etc/hosts <<'HOSTS_EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   archintosh.localdomain   archintosh
HOSTS_EOF

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm

# Set graphical target as default (boot into GUI)
systemctl set-default graphical.target

# Write a clean mkinitcpio.conf for the installed system
# (the live ISO version contains archiso-specific hooks that won't work)
cat > /etc/mkinitcpio.conf <<'MKINIT_EOF'
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)
MKINIT_EOF

# Rebuild initramfs with clean config
mkinitcpio -P

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
CHROOT_EOF

# --- Interactive section: passwords and user creation ---
echo ""
echo "🔑 Set root password:"
arch-chroot /mnt passwd <&3

echo ""
read -r -p "👤 Enter username for your account: " USERNAME <&3

# Validate username: must be lowercase alphanumeric, start with a letter, 1-32 chars
if [[ ! "$USERNAME" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
    die "Invalid username '$USERNAME'. Must start with a lowercase letter, contain only [a-z0-9_-], and be 1-32 characters."
fi

arch-chroot /mnt useradd -m -G wheel,audio,video,storage,network,power -s /bin/zsh "$USERNAME"

echo "🔑 Set password for $USERNAME:"
arch-chroot /mnt passwd "$USERNAME" <&3

# --- Copy skeleton configs to the new user ---
log "Copying desktop configurations to /home/$USERNAME..."
if [ -d /mnt/etc/skel/.config ]; then
    cp -rT /mnt/etc/skel/.config "/mnt/home/$USERNAME/.config"
fi
if [ -d /mnt/etc/skel/.local ]; then
    cp -rT /mnt/etc/skel/.local "/mnt/home/$USERNAME/.local"
fi
if [ -f /mnt/etc/skel/.zshrc ]; then
    cp /mnt/etc/skel/.zshrc "/mnt/home/$USERNAME/.zshrc"
fi
arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

# --- Copy AUR helper scripts ---
log "Copying AUR helper scripts to /home/$USERNAME..."
for f in install_aur_packages.sh AUR_PACKAGES_README.txt; do
    if [ -f "/root/$f" ]; then
        cp "/root/$f" "/mnt/home/$USERNAME/$f"
        arch-chroot /mnt chown "$USERNAME:$USERNAME" "/home/$USERNAME/$f"
    fi
done
arch-chroot /mnt chmod +x "/home/$USERNAME/install_aur_packages.sh" 2>/dev/null || true

# --- Success ---
INSTALL_SUCCESS=true

echo ""
echo "================================================"
echo "  ✅ Installation complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. umount -R /mnt"
echo "  2. reboot"
echo ""
echo "After reboot:"
echo "  - Log in as '$USERNAME' at the SDDM login screen"
echo "  - Run ~/install_aur_packages.sh to install Brave, Spotify, and VS Code"
echo ""
echo "📄 Installation log saved to: $LOG_FILE"
echo ""
