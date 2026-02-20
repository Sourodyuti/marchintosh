#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "  AUR Package Installation Helper"
echo "=========================================="
echo ""

# --- Root check ---
if [ "$EUID" -eq 0 ]; then
    echo "❌ Do not run this as root!"
    echo "Run as your regular user after logging in."
    exit 1
fi

# --- Install yay (AUR helper) ---
echo "📦 Installing yay (AUR helper)..."

YAY_DIR="$(mktemp -d)"
trap 'rm -rf "$YAY_DIR"' EXIT

git clone https://aur.archlinux.org/yay.git "$YAY_DIR/yay"
cd "$YAY_DIR/yay"
makepkg -si --noconfirm

echo ""
echo "📦 Installing AUR packages:"
echo ""

# --- Install AUR packages ---
yay -S --noconfirm --needed \
    brave-bin \
    spotify \
    visual-studio-code-bin

echo ""
echo "✅ AUR packages installed successfully!"
echo ""
