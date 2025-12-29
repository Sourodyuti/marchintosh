#!/usr/bin/env bash

if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
  echo "⚠️ Warning: Not running Wayland (current: $XDG_SESSION_TYPE)"
fi

if ! command -v pacman >/dev/null; then
  echo "❌ This script is for Arch Linux only."
  exit 1
fi
