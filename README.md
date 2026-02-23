# Dotfiles

Personal dotfiles for a Hyprland/Wayland desktop environment.

## Included Configurations

| Directory | Application | Description |
|-----------|-------------|-------------|
| `fish` | [Fish](https://fishshell.com/) | Shell configuration |
| `hypr` | [Hyprland](https://hyprland.org/) | Window manager, lock screen (hyprlock), and idle daemon (hypridle) |
| `kitty` | [Kitty](https://sw.kovidgoyal.net/kitty/) | Terminal emulator |
| `waybar` | [Waybar](https://github.com/Alexays/Waybar) | Status bar |
| `rofi` | [Rofi](https://github.com/lbonn/rofi) | Application launcher |
| `mako` | [Mako](https://github.com/emersion/mako) | Notification daemon |
| `gtk` | GTK 3 | Theme overrides |
| `wallust` | [Wallust](https://codeberg.org/explosion-mental/wallust) | Wallpaper-based color scheme generator with templates for kitty, waybar, rofi, mako, wlogout, hyprland, hyprlock, and VS Code |
| `waypaper` | [Waypaper](https://github.com/anufrievroman/waypaper) | Wallpaper manager |
| `wlogout` | [Wlogout](https://github.com/ArtsyMacaw/wlogout) | Logout menu |

## Scripts

- **`scripts/wall.sh`** — Sets a wallpaper with [swww](https://github.com/LGFae/swww), generates a matching color scheme via Wallust, caches the image for the lock screen, and reloads Waybar.

  ```bash
  ./scripts/wall.sh /path/to/wallpaper.png
  ```
