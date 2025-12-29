#!/usr/bin/env bash
set -e

# Prevent running as root
if [ "$EUID" -eq 0 ]; then
  echo "❌ Do not run Arch-intosh setup as root"
  exit 1
fi


echo "🍎 Arch-intosh setup starting…"

bash scripts/00-checks.sh
bash scripts/01-packages.sh
bash scripts/02-fonts.sh
bash scripts/03-zsh-starship.sh
bash scripts/04-konsole.sh
bash scripts/05-fontconfig.sh
bash scripts/06-kde-effects.sh
bash scripts/10-nvidia-cuda.sh
bash scripts/20-plasma-theme.sh

echo "✅ Arch-intosh setup complete."
echo "➡ Logging out recommended."
