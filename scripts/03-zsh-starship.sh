#!/usr/bin/env bash

# Enable starship
grep -q "starship init zsh" ~/.zshrc 2>/dev/null || \
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# Starship config
mkdir -p ~/.config
cat <<'EOF' > ~/.config/starship.toml
add_newline = false

format = """
$directory\
$git_branch\
$git_status\
$python\
$cmd_duration\
$line_break\
$character
"""

[directory]
style = "bold blue"

[git_branch]
symbol = " "
style = "bold purple"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
EOF
