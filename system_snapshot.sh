#!/bin/bash
set -euo pipefail

echo "=== COLLECTING SYSTEM INFORMATION ==="

# Create output directory
OUTPUT_DIR="system_info"
mkdir -p "$OUTPUT_DIR"

# 1. Package lists
echo "📦 Collecting package information..."
pacman -Qe > "$OUTPUT_DIR/packages_explicit.txt"
pacman -Q  > "$OUTPUT_DIR/packages_all.txt"
pacman -Qm > "$OUTPUT_DIR/packages_aur.txt" 2>/dev/null || echo "No AUR packages" > "$OUTPUT_DIR/packages_aur.txt"

# 2. System configuration
echo "⚙️  Collecting system configuration..."
hostnamectl  > "$OUTPUT_DIR/hostname.txt" 2>&1 || true
localectl    > "$OUTPUT_DIR/locale.txt" 2>&1 || true
timedatectl  > "$OUTPUT_DIR/timezone.txt" 2>&1 || true
echo "${XDG_CURRENT_DESKTOP:-unknown}" > "$OUTPUT_DIR/desktop.txt"
echo "${XDG_SESSION_TYPE:-unknown}"    > "$OUTPUT_DIR/session_type.txt"
uname -r > "$OUTPUT_DIR/kernel.txt"

# 3. Enabled services
echo "🔧 Collecting enabled services..."
systemctl list-unit-files --state=enabled --no-pager > "$OUTPUT_DIR/enabled_services.txt" 2>&1 || true

# 4. Display manager
echo "🖥️  Detecting display manager..."
systemctl status display-manager 2>&1 | head -10 > "$OUTPUT_DIR/display_manager.txt" || true

# 5. Hardware info
echo "🔌 Collecting hardware information..."
lspci | grep -E 'VGA|3D' > "$OUTPUT_DIR/gpu.txt" 2>/dev/null || echo "No GPU detected" > "$OUTPUT_DIR/gpu.txt"
lsmod > "$OUTPUT_DIR/kernel_modules.txt"

# 6. Boot info
echo "🥾 Collecting boot information..."
ls -la /boot/ > "$OUTPUT_DIR/boot_files.txt" 2>&1 || true
efibootmgr -v > "$OUTPUT_DIR/efi_boot.txt" 2>&1 || echo "Legacy BIOS" > "$OUTPUT_DIR/efi_boot.txt"
lsblk -f > "$OUTPUT_DIR/partitions.txt"

# 7. User info
echo "👤 Collecting user information..."
whoami > "$OUTPUT_DIR/username.txt"
groups  > "$OUTPUT_DIR/user_groups.txt"
du -sh ~ > "$OUTPUT_DIR/home_size.txt" 2>/dev/null || echo "unknown" > "$OUTPUT_DIR/home_size.txt"

# 8. Network info
echo "🌐 Collecting network configuration..."
ip link show > "$OUTPUT_DIR/network_interfaces.txt"
systemctl status NetworkManager 2>&1 | head -10 > "$OUTPUT_DIR/network_manager.txt" || true

# 9. Config directory structure
echo "📁 Mapping config directories..."
ls -la ~/.config/      > "$OUTPUT_DIR/config_dirs.txt" 2>&1 || true
ls -la ~/.local/share/ > "$OUTPUT_DIR/local_share.txt" 2>&1 || true

# 10. Fonts and themes
echo "🎨 Collecting customization info..."
fc-list > "$OUTPUT_DIR/fonts.txt" 2>&1 || true
ls -R ~/.themes ~/.local/share/themes /usr/share/themes 2>/dev/null > "$OUTPUT_DIR/themes.txt" || true
ls -R ~/.icons ~/.local/share/icons /usr/share/icons 2>/dev/null | head -100 > "$OUTPUT_DIR/icons.txt" || true

echo ""
echo "✅ System snapshot complete!"
echo "📂 All information saved to: $OUTPUT_DIR/"
echo ""
echo "=== QUICK SUMMARY ==="
echo "Hostname: $(hostnamectl --static 2>/dev/null || echo 'unknown')"
echo "Desktop:  $(cat "$OUTPUT_DIR/desktop.txt")"
echo "Packages: $(wc -l < "$OUTPUT_DIR/packages_explicit.txt") explicit, $(wc -l < "$OUTPUT_DIR/packages_all.txt") total"
echo "Home:     $(cat "$OUTPUT_DIR/home_size.txt")"
echo "GPU:      $(cat "$OUTPUT_DIR/gpu.txt")"
echo "Kernel:   $(cat "$OUTPUT_DIR/kernel.txt")"
