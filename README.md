# Dotfiles

Personal dotfiles for a Hyprland/Wayland desktop environment.

## Screenshots

[![Screenshot 1](/images/1771915512_grim.png)](/images/1771915512_grim.png)
[![Screenshot 2](/images/1771915652_grim.png)](/images/1771915652_grim.png)
[![Screenshot 3](/images/1771915716_grim.png)](/images/1771915716_grim.png)

## ✨ Dynamic Colors with Wallust

The main feature of this setup is **fully dynamic theming** powered by [Wallust](https://codeberg.org/explosion-mental/wallust). Every time a new wallpaper is set, Wallust extracts a color palette from the image and applies it across the entire desktop — no manual tweaking required.

**Themed components:** Kitty · Waybar · Rofi · Mako · Wlogout · Hyprland · Hyprlock · VS Code · Qt6ct

## ⌨️ Essential Keybinds

Here are the primary keybindings to navigate the desktop and launch the included utilities. 

*(Note: The `SUPER` key is usually the Windows / Command key)*

| Shortcut | Action | Application |
| :--- | :--- | :--- |
| `SUPER` + `Return` | Open Terminal | **Kitty** |
| `SUPER` + `Space` | Open App Launcher | **Rofi** |
| `SUPER` + `V` | Open Clipboard History | **Cliphist** + **Rofi** |
| `SUPER` + `E` | Open File Manager | **Thunar** |
| `SUPER` + `M` | Open Power / Logout Menu | **Wlogout** |
| `SUPER` + `L` | Lock Session | **Hyprlock** |
| `SUPER` + `W` | Close active window | Hyprland |
| `SUPER` + `Q` | Toggle floating mode | Hyprland |
| `SUPER` + `1`-`9` | Switch to workspace 1-9 | Hyprland |
| `SUPER` + `Shift` + `1`-`9` | Move active window to workspace 1-9 | Hyprland |

## Included Configurations

| Directory | Application | Description |
| --- | --- | --- |
| `cliphist` | [Cliphist](https://github.com/sentriz/cliphist) | Wayland clipboard manager |
| `fish` | [Fish](https://fishshell.com/) | Shell configuration |
| `gtk` | GTK 3 | Theme overrides |
| `hypr` | [Hyprland](https://hyprland.org/) | Window manager, lock screen (hyprlock), and idle daemon (hypridle) |
| `kitty` | [Kitty](https://sw.kovidgoyal.net/kitty/) | Terminal emulator |
| `mako` | [Mako](https://github.com/emersion/mako) | Notification daemon |
| `rofi` | [Rofi](https://github.com/lbonn/rofi) | Application launcher (Wayland fork) |
| `scripts` | Custom Scripts | Helper scripts for the desktop environment |
| `systemd` | Systemd | User-level systemd service configurations |
| `uwsm` | [UWSM](https://github.com/Vladimir-csp/uwsm) | Universal Wayland Session Manager |
| `wallust` | [Wallust](https://codeberg.org/explosion-mental/wallust) | Wallpaper-based color scheme generator with templates |
| `waybar` | [Waybar](https://github.com/Alexays/Waybar) | Status bar |
| `waypaper` | [Waypaper](https://github.com/anufrievroman/waypaper) | Wallpaper manager |
| `wlogout` | [Wlogout](https://github.com/ArtsyMacaw/wlogout) | Logout menu |

## Prerequisites

Before stowing these dotfiles, ensure you have the underlying applications installed on your system.
* **Core:** `stow`, `hyprland`, `uwsm`
* **Theming:** `wallust`, `waypaper`
* **Utilities:** `kitty`, `waybar`, `rofi-wayland`, `mako`, `wlogout`, `cliphist`, `Hyprlock`, `Hypridle` 

## Installation

The dotfiles are managed with [GNU Stow](https://www.gnu.org/software/stow/), which symlinks each package into your home directory.

```bash
# Clone the repo
git clone https://github.com/DerpBoy77/dot-files.git ~/dot-files
cd ~/dot-files

# Install all packages at once
stow cliphist fish gtk hypr kitty mako rofi scripts systemd uwsm wallust waybar waypaper wlogout

# Or install individual packages
stow hypr
stow kitty waybar
```

To uninstall a package, use the `-D` flag:

```bash
stow -D hypr
```