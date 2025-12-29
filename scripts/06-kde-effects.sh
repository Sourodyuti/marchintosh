#!/usr/bin/env bash

kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Effect-Blur --key BlurStrength 8
kwriteconfig6 --file kwinrc --group Effect-Blur --key NoiseStrength 2

qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
