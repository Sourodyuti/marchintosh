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
exec 3>&1
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }
die() {
    clear
    echo "❌ $*" >&3
    echo "❌ $*" >&2
    exit 1
}

# --- Root check ---
if [ "$EUID" -ne 0 ]; then
    die "Please run as root: sudo ./$SCRIPT_NAME"
fi

# Ensure dialog is installed
if ! command -v dialog &> /dev/null; then
    die "dialog is not installed but is required for the installer UI."
fi

# --- Helper functions for TUI ---
show_msg() {
    dialog --backtitle "Archintosh Installer" --title "$1" --msgbox "$2" 8 60 >&3
}

# --- Cleanup trap ---
INSTALL_SUCCESS=false

cleanup() {
    clear
    if [ "$INSTALL_SUCCESS" = false ]; then
        echo "" >&3
        echo "⚠️  Installation interrupted or failed. Cleaning up..." >&3
        umount -R /mnt 2>/dev/null || true
        echo "📄 See $LOG_FILE for details." >&3
    fi
}
trap cleanup EXIT
trap 'exit 1' INT TERM

show_msg "Welcome" "Welcome to the Archintosh Installer!\n\nThis script will guide you through installing Arch Linux with KDE Plasma."

# --- Disk selection ---
while true; do
    log "Listing available disks..."
    
    # Generate disk list for dialog
    DISKS=()
    while read -r name size model; do
        DISKS+=("$name" "$size - $model")
    done < <(lsblk -d -n -o NAME,SIZE,MODEL | grep -v 'loop' | grep -v 'rom')
    
    if [ ${#DISKS[@]} -eq 0 ]; then
        die "No usable disks found!"
    fi
    
    DISK=$(dialog --backtitle "Archintosh Installer" --title "Target Disk" \
           --clear --menu "Select the disk to install Archintosh to.\n\nWARNING: ALL DATA ON THE SELECTED DISK WILL BE ERASED." 15 60 5 "${DISKS[@]}" \
           3>&1 1>&2 2>&3)
    
    if [ "$?" -ne 0 ]; then
        log "User cancelled disk selection."
        exit 0
    fi
    
    if [ -b "/dev/$DISK" ]; then
        break
    else
        show_msg "Error" "Selected disk /dev/$DISK is invalid or not found."
    fi
done

dialog --backtitle "Archintosh Installer" --title "Confirm Erase" \
       --yesno "Are you absolutely sure you want to format /dev/$DISK?\n\nThis action cannot be undone." 8 60 >&3
if [ $? -ne 0 ]; then
     log "User aborted at confirmation."
     exit 0
fi

# --- Filesystem selection ---
FS_TYPE=$(dialog --backtitle "Archintosh Installer" --title "Root Filesystem" \
          --clear --menu "Select your preferred filesystem for the root partition:" 12 60 2 \
          "ext4" "Standard, reliable filesystem" \
          "btrfs" "Modern filesystem with subvolume & snapshot support" \
          3>&1 1>&2 2>&3)

if [ "$?" -ne 0 ]; then FS_TYPE="ext4"; fi
log "Selected filesystem: $FS_TYPE"

# --- Partitioning ---
log "Partitioning /dev/$DISK..."
dialog --backtitle "Archintosh Installer" --infobox "Partitioning /dev/$DISK..." 5 50 >&3

parted "/dev/$DISK" --script mklabel gpt
parted "/dev/$DISK" --script mkpart ESP fat32 1MiB 512MiB
parted "/dev/$DISK" --script set 1 esp on
parted "/dev/$DISK" --script mkpart primary "$FS_TYPE" 512MiB 100%

# Wait for kernel to re-read partition table
sleep 2
partprobe "/dev/$DISK" 2>/dev/null || true
sleep 2

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
dialog --backtitle "Archintosh Installer" --infobox "Formatting partitions..." 5 50 >&3

mkfs.fat -F32 "/dev/$PART1"

if [ "$FS_TYPE" = "btrfs" ]; then
    mkfs.btrfs -f "/dev/$PART2"
    mount "/dev/$PART2" /mnt
    
    log "Creating Btrfs subvolumes..."
    btrfs su cr /mnt/@
    btrfs su cr /mnt/@home
    btrfs su cr /mnt/@cache
    btrfs su cr /mnt/@log
    
    umount /mnt
    
    log "Mounting Btrfs subvolumes..."
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "/dev/$PART2" /mnt
    mkdir -p /mnt/{home,var/cache,var/log,boot}
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "/dev/$PART2" /mnt/home
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@cache "/dev/$PART2" /mnt/var/cache
    mount -o noatime,compress=zstd,space_cache=v2,subvol=@log "/dev/$PART2" /mnt/var/log
else
    mkfs.ext4 -F "/dev/$PART2"
    mount "/dev/$PART2" /mnt
    mkdir -p /mnt/boot
fi

mount "/dev/$PART1" /mnt/boot


# --- Package installation ---
dialog --backtitle "Archintosh Installer" --infobox "Starting package installation from live ISO...\n\nThis will take several minutes." 6 60 >&3

log "Building package list from live ISO (filtering ISO-only packages)..."

ISO_ONLY_PKGS="archiso|mkinitcpio-archiso|mkinitcpio-nfs-utils|syslinux"
ISO_ONLY_PKGS+="|memtest86\\+|memtest86\\+-efi|edk2-ovmf|squashfs-tools"
PACKAGES=$(pacman -Qq | grep -v -E "^(${ISO_ONLY_PKGS})$")
PACKAGES=$(echo "$PACKAGES" | grep -v -E '^(base|linux|linux-firmware)$')

# Hardware detection
CPU_VENDOR=$(lscpu | grep "Vendor ID" | awk '{print $3}')
case "$CPU_VENDOR" in
    GenuineIntel) PACKAGES="$PACKAGES intel-ucode" ;;
    AuthenticAMD) PACKAGES="$PACKAGES amd-ucode" ;;
    *) log "Warning: Unknown CPU vendor '$CPU_VENDOR', skipping microcode." ;;
esac

if lspci | grep -i vga | grep -iq nvidia; then
    log "NVIDIA GPU detected. Preserving nvidia drivers."
else
    log "No NVIDIA GPU detected. Stripping nvidia drivers."
    PACKAGES=$(echo "$PACKAGES" | grep -v -E '^(nvidia|nvidia-utils|nvidia-open|nvidia-settings)$')
fi

# Ensure git and base-devel are added for yay
if ! echo "$PACKAGES" | grep -q "base-devel"; then PACKAGES="$PACKAGES base-devel"; fi
if ! echo "$PACKAGES" | grep -q "git"; then PACKAGES="$PACKAGES git"; fi

log "Installing base system + packages..."
# shellcheck disable=SC2086
pacstrap /mnt base linux linux-firmware $PACKAGES


# --- fstab ---
log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab


# --- Dynamic Swapfile ---
dialog --backtitle "Archintosh Installer" --infobox "Configuring swap & system settings..." 5 50 >&3
log "Configuring dynamic swapfile..."

TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
SWAP_MB=4096

if [ "$TOTAL_RAM_MB" -lt 4096 ]; then
    SWAP_MB=$TOTAL_RAM_MB
elif [ "$TOTAL_RAM_MB" -gt 8192 ]; then
    SWAP_MB=8192
else
    SWAP_MB=$TOTAL_RAM_MB
fi

log "Creating swapfile of size ${SWAP_MB}M..."
if [ "$FS_TYPE" = "btrfs" ]; then
    # Btrfs requires special swapfile handling
    arch-chroot /mnt btrfs filesystem mkswapfile --size "${SWAP_MB}m" /swapfile
else
    arch-chroot /mnt fallocate -l "${SWAP_MB}M" /swapfile
    arch-chroot /mnt chmod 600 /swapfile
    arch-chroot /mnt mkswap /swapfile
fi
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab


# --- Timezone selection ---
LIVE_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
TIMEZONE=$(dialog --backtitle "Archintosh Installer" --title "Timezone" \
           --clear --inputbox "Enter your timezone (e.g., America/New_York, Europe/London, Asia/Kolkata):" 10 60 "$LIVE_TZ" \
           3>&1 1>&2 2>&3)

if [ -z "$TIMEZONE" ] || [ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
    show_msg "Warning" "Invalid timezone '$TIMEZONE', defaulting to UTC."
    TIMEZONE="UTC"
fi


# --- System configuration (non-interactive heredoc) ---
log "Configuring system (timezone, locale, hostname, services, bootloader)..."
arch-chroot /mnt /bin/bash <<CHROOT_EOF
# Set timezone
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc

# Set locale
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
systemctl set-default graphical.target

# Mkinitcpio
cat > /etc/mkinitcpio.conf <<'MKINIT_EOF'
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)
MKINIT_EOF

mkinitcpio -P

# Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
CHROOT_EOF


# --- Interactive section: passwords and user creation ---
while true; do
    ROOT_PW1=$(dialog --backtitle "Archintosh Installer" --title "Root Password" --insecure --passwordbox "Enter password for the root (administrator) account:" 10 60 3>&1 1>&2 2>&3)
    ROOT_PW2=$(dialog --backtitle "Archintosh Installer" --title "Confirm Root Password" --insecure --passwordbox "Please enter the root password again to confirm:" 10 60 3>&1 1>&2 2>&3)
    
    if [ "$ROOT_PW1" == "$ROOT_PW2" ] && [ -n "$ROOT_PW1" ]; then
        echo "root:$ROOT_PW1" | arch-chroot /mnt chpasswd
        break
    else
        show_msg "Error" "Passwords did not match or were empty. Try again."
    fi
done

while true; do
    USERNAME=$(dialog --backtitle "Archintosh Installer" --title "Create User" --inputbox "Enter a username for your main account:\n\n(Lowercase letters, numbers, and hyphens only, starting with a letter)" 10 60 3>&1 1>&2 2>&3)
    
    if [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        arch-chroot /mnt useradd -m -G wheel,audio,video,storage,network,power -s /bin/zsh "$USERNAME"
        break
    else
        show_msg "Error" "Invalid username. Must start with a lowercase letter and contain only lowercase letters, numbers, or hyphens."
    fi
done

while true; do
    USER_PW1=$(dialog --backtitle "Archintosh Installer" --title "User Password" --insecure --passwordbox "Enter password for $USERNAME:" 10 60 3>&1 1>&2 2>&3)
    USER_PW2=$(dialog --backtitle "Archintosh Installer" --title "Confirm User Password" --insecure --passwordbox "Please enter the password again to confirm:" 10 60 3>&1 1>&2 2>&3)
    
    if [ "$USER_PW1" == "$USER_PW2" ] && [ -n "$USER_PW1" ]; then
        echo "$USERNAME:$USER_PW1" | arch-chroot /mnt chpasswd
        break
    else
        show_msg "Error" "Passwords did not match or were empty. Try again."
    fi
done


# --- Copy skeleton configs to the new user ---
log "Copying desktop configurations to /home/$USERNAME..."
dialog --backtitle "Archintosh Installer" --infobox "Finalizing configurations and installing AUR packages..." 5 50 >&3

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


# --- Pre-install AUR Packages via yay ---
log "Building yay and installing AUR packages..."
arch-chroot /mnt /bin/bash <<CHROOT_EOF
# Build yay as the new user
sudo -u $USERNAME bash -c 'cd /tmp && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm'

# Install desired AUR packages
sudo -u $USERNAME yay -S --noconfirm --needed brave-bin spotify visual-studio-code-bin

# Clean up
rm -rf /tmp/yay-bin
CHROOT_EOF

# --- Success ---
INSTALL_SUCCESS=true
clear
echo "" >&3
echo "================================================" >&3
echo "  ✅ Installation complete!" >&3
echo "================================================" >&3
echo "" >&3
echo "Press OK to exit the installer. You can then reboot your system." | dialog --title "Success" --msgbox "$(cat)" 10 50 >&3
echo "Next steps:" >&3
echo "  1. umount -R /mnt" >&3
echo "  2. reboot" >&3
echo "" >&3
echo "After reboot:" >&3
echo "  - Log in as '$USERNAME' at the SDDM login screen" >&3
echo "" >&3
echo "📄 Installation log saved to: $LOG_FILE" >&3
echo "" >&3
