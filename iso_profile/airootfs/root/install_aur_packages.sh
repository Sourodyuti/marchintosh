#!/bin/bash

echo "=========================================="
echo "  AUR Package Installation Helper"
echo "=========================================="
echo ""

if [ "$EUID" -eq 0 ]; then 
   echo "❌ Do not run this as root!"
   echo "Run as your regular user after logging in"
   exit 1
fi

echo "Installing yay (AUR helper)..."
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo ""
echo "📦 Installing AUR packages from your original system:"
echo ""

# Install your AUR packages
yay -S --noconfirm \
    brave-bin \
    spotify \
    visual-studio-code-bin

echo ""
echo "✅ AUR packages installed!"
