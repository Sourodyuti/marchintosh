#!/bin/bash
echo "=== COLLECTING SYSTEM INFORMATION ==="

# Create output directory
mkdir -p system_info

# 1. Package lists
echo "📦 Collecting package information..."
pacman -Qe > system_info/packages_explicit.txt
pacman -Q > system_info/packages_all.txt
pacman -Qm > system_info/packages_aur.txt 2>/dev/null || echo "No AUR packages" > system_info/packages_aur.txt

# 2. System configuration
echo "⚙️  Collecting system configuration..."
hostnamectl > system_info/hostname.txt 2>&1
localectl > system_info/locale.txt 2>&1
timedatectl > system_info/timezone.txt 2>&1
echo $XDG_CURRENT_DESKTOP > system_info/desktop.txt
echo $XDG_SESSION_TYPE > system_info/session_type.txt
uname -r > system_info/kernel.txt

# 3. Enabled services
echo "🔧 Collecting enabled services..."
systemctl list-unit-files --state=enabled --no-pager > system_info/enabled_services.txt

# 4. Display manager
echo "🖥️  Detecting display manager..."
systemctl status display-manager 2>&1 | head -10 > system_info/display_manager.txt

# 5. Hardware info
echo "🔌 Collecting hardware information..."
lspci | grep -E 'VGA|3D' > system_info/gpu.txt
lsmod > system_info/kernel_modules.txt

# 6. Boot info
echo "🥾 Collecting boot information..."
ls -la /boot/ > system_info/boot_files.txt 2>&1
efibootmgr -v > system_info/efi_boot.txt 2>&1 || echo "Legacy BIOS" > system_info/efi_boot.txt
lsblk -f > system_info/partitions.txt

# 7. User info
echo "👤 Collecting user information..."
whoami > system_info/username.txt
groups > system_info/user_groups.txt
du -sh ~ > system_info/home_size.txt

# 8. Network info
echo "🌐 Collecting network configuration..."
ip link show > system_info/network_interfaces.txt
systemctl status NetworkManager 2>&1 | head -10 > system_info/network_manager.txt

# 9. Config directory structure
echo "📁 Mapping config directories..."
ls -la ~/.config/ > system_info/config_dirs.txt 2>&1
ls -la ~/.local/share/ > system_info/local_share.txt 2>&1

# 10. Fonts and themes
echo "🎨 Collecting customization info..."
fc-list > system_info/fonts.txt 2>&1
ls -R ~/.themes ~/.local/share/themes /usr/share/themes 2>/dev/null > system_info/themes.txt
ls -R ~/.icons ~/.local/share/icons /usr/share/icons 2>/dev/null | head -100 > system_info/icons.txt

echo ""
echo "✅ System snapshot complete!"
echo "📂 All information saved to: system_info/"
echo ""
echo "=== QUICK SUMMARY ==="
echo "Hostname: $(cat system_info/hostname.txt | grep 'Static hostname' | awk '{print $3}')"
echo "Desktop: $(cat system_info/desktop.txt)"
echo "Packages: $(wc -l < system_info/packages_explicit.txt) explicit, $(wc -l < system_info/packages_all.txt) total"
echo "Home size: $(cat system_info/home_size.txt)"
echo "GPU: $(cat system_info/gpu.txt)"
echo "Kernel: $(cat system_info/kernel.txt)"
