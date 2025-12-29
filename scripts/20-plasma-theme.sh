#!/usr/bin/env bash
set -e

echo "🎨 Installing WhiteSur KDE theme…"

sudo pacman -S --needed --noconfirm \
  git \
  plasma-workspace \
  kde-cli-tools

WORKDIR="$HOME/.cache/arch-intosh"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [ ! -d "WhiteSur-kde" ]; then
  git clone https://github.com/vinceliuice/WhiteSur-kde.git
fi

cd WhiteSur-kde
./install.sh

echo "🎨 Installing WhiteSur icons & cursors…"

if [ ! -d "../WhiteSur-icon-theme" ]; then
  git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
fi

cd ../WhiteSur-icon-theme
./install.sh

echo "🖱️ Installing WhiteSur cursors…"

if [ ! -d "../WhiteSur-cursors" ]; then
  git clone https://github.com/vinceliuice/WhiteSur-cursors.git
fi

cd ../WhiteSur-cursors
./install.sh

echo "⚙️ Applying KDE defaults…"

kwriteconfig6 --file kdeglobals --group General --key ColorScheme WhiteSurDark
kwriteconfig6 --file kdeglobals --group Icons --key Theme WhiteSur-dark
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XIA"
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true

qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo "✅ WhiteSur KDE theme installed. Log out & log in."
