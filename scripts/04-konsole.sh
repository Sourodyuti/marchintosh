#!/usr/bin/env bash

PROFILE="$HOME/.local/share/konsole/Profile 1.profile"
mkdir -p "$(dirname "$PROFILE")"

kwriteconfig6 --file "$PROFILE" --group Appearance --key Font \
"JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"

kwriteconfig6 --file "$PROFILE" --group Appearance --key ColorScheme ArchintoshDark
kwriteconfig6 --file "$PROFILE" --group Appearance --key UseTransparency true
kwriteconfig6 --file "$PROFILE" --group Appearance --key Transparency 15
