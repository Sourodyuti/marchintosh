#!/bin/bash
set -e

echo "================================================"
echo "  Archintosh Installation Script"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "❌ Please run as root (sudo ./install.sh)"
   exit 1
fi

# List disks
echo "Available disks:"
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo ""
read -p "Enter target disk (e.g., sda, nvme0n1): " DISK

if [ ! -b "/dev/$DISK" ]; then
    echo "❌ Disk /dev/$DISK not found!"
    exit 1
fi

echo ""
echo "⚠️  WARNING: This will erase ALL data on /dev/$DISK"
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "🔧 Partitioning disk..."
parted /dev/$DISK --script mklabel gpt
parted /dev/$DISK --script mkpart ESP fat32 1MiB 512MiB
parted /dev/$DISK --script set 1 esp on
parted /dev/$DISK --script mkpart primary ext4 512MiB 100%

# Determine partition names
if [[ $DISK == nvme* ]]; then
    PART1="${DISK}p1"
    PART2="${DISK}p2"
else
    PART1="${DISK}1"
    PART2="${DISK}2"
fi

echo "🔧 Formatting partitions..."
mkfs.fat -F32 /dev/$PART1
mkfs.ext4 -F /dev/$PART2

echo "🔧 Mounting filesystems..."
mount /dev/$PART2 /mnt
mkdir -p /mnt/boot
mount /dev/$PART1 /mnt/boot

echo "📦 Installing base system..."
pacstrap /mnt base linux linux-firmware

echo "📦 Installing all packages from live ISO..."
pacstrap /mnt $(pacman -Qq)

echo "🔧 Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "🔧 Configuring system..."
arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
# Set timezone
ln -sf /usr/share/zoneinfo/$(timedatectl show --property=Timezone --value) /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "archintosh" > /etc/hostname

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Set root password
echo "Set root password:"
passwd

# Create user
read -p "Enter username: " USERNAME
useradd -m -G wheel,audio,video,storage -s /bin/bash $USERNAME
echo "Set password for $USERNAME:"
passwd $USERNAME

# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

CHROOT_EOF

echo ""
echo "✅ Installation complete!"
echo ""
echo "You can now:"
echo "  1. umount -R /mnt"
echo "  2. reboot"
echo ""
