# Reggie Ubuntu Workspace

Automated Ubuntu workspace setup - opens browser tabs and apps on login.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/blueivy828/reggie-ubuntu-workspace/main/setup.sh | bash
```

## What It Does

- Installs dev tools (Node.js, Git, pnpm, VS Code, Cursor, Antigravity)
- Downloads workspace launcher to Desktop
- Creates autostart entry for login
- Sets up bash aliases (git shortcuts, common commands)

## Customize

Edit `reggie-workspace.sh` on your Desktop:

```bash
#!/bin/bash

# Open browser tabs
xdg-open "https://your-urls-here.com" &

# Open applications
gnome-terminal &
obsidian &
```

**Specific browser:** Replace `xdg-open` with `google-chrome`, `firefox`, or `brave-browser`

## Uninstall

```bash
rm ~/.config/autostart/reggie-workspace.desktop
rm ~/Desktop/reggie-workspace.sh
```

## Troubleshooting

**Permission denied:**
```bash
chmod +x ~/Desktop/reggie-workspace.sh
```

**Autostart not working:** Check `~/.config/autostart/reggie-workspace.desktop` exists

## Requirements

- Ubuntu 20.04+ / Debian-based distro
- bash
- curl
- snap (for VS Code)
