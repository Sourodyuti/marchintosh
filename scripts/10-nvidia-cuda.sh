#!/usr/bin/env bash

set -e

echo "🔍 Checking for NVIDIA GPU…"

if ! lspci | grep -qi nvidia; then
  echo "ℹ️ No NVIDIA GPU detected. Skipping NVIDIA/CUDA setup."
  exit 0
fi

echo "✅ NVIDIA GPU detected."

read -rp "Install NVIDIA drivers + CUDA? [y/N]: " yn
case $yn in
  [Yy]* ) ;;
  * ) echo "Skipping NVIDIA/CUDA."; exit 0 ;;
esac

echo "📦 Installing NVIDIA drivers…"

sudo pacman -S --needed --noconfirm \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  lib32-nvidia-utils

echo "📦 Installing CUDA toolkit…"

sudo pacman -S --needed --noconfirm cuda

echo "⚙️ Enabling NVIDIA DRM (Wayland compatibility)…"

sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sudo sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="nvidia-drm.modeset=1"/' /etc/default/grub

sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "✅ NVIDIA + CUDA installed. Reboot required."

