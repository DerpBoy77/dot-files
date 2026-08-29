# Dotfiles

Personal dotfiles for a modern, fluid **Hyprland** (Wayland) desktop environment featuring **Quickshell** with Apple-style Dynamic Island physics, fully dynamic theming powered by **Wallust**, and Lua-based configuration.

---

## 📸 Screenshots

[![Screenshot 1](/images/1771915512_grim.png)](/images/1771915512_grim.png)
[![Screenshot 2](/images/1771915652_grim.png)](/images/1771915652_grim.png)
[![Screenshot 3](/images/1771915716_grim.png)](/images/1771915716_grim.png)

---

## ✨ Dynamic Colors with Wallust

The visual core of this setup is **dynamic palette extraction** powered by [Wallust](https://codeberg.org/explosion-mental/wallust). Whenever you select a new wallpaper (via **Waypaper** or the included wallpaper script), Wallust automatically derives a 16-color palette and recompiles configuration templates across all applications in real time.

- **Unified Glassmorphism**: Standardized frosted glass baseline (`0.70` background opacity, `0.40` card opacity, and `0.16` border glass) across Quickshell, Kitty, GTK 3/4, and Rofi.
- **Themed Components**: Quickshell · Kitty · Rofi · Hyprland · Hyprlock · Wlogout · GTK 3/4 · Zen Browser · VS Code · Qt6ct

---

## 🏝️ Quickshell Dynamic Island Status Bar

The status bar and notification server are built from scratch using [Quickshell](https://quickshell.outfoxxed.me/) with a clean, 4-tier modular architecture:

```
quickshell/.config/quickshell/
├── Theme.qml                 # Central design system (typography, metrics, animation presets)
├── Colors.qml                # Live Wallust palette singleton & glass helpers
├── shell.qml                 # Main bar window entry point
├── services/                 # Headless system services
│   ├── NotificationService   # Notification server, queue management & auto-dismissal
│   ├── AudioService          # Reactive Pipewire audio sink/source & stream mixer
│   ├── NetworkService        # Wi-Fi & Ethernet state tracker, telemetry & link speed
│   └── BluetoothService      # Adapter management & real-time device discovery
├── widgets/                  # Reusable UI building blocks
│   ├── DynamicIslandPopup    # Morphing island window with spring animations
│   ├── GlassPill             # Frosted glass capsule container
│   ├── SliderTrack           # Smooth draggable volume/input slider
│   ├── ToggleSwitch          # Fluid animated toggle switch
│   └── ActionIconButton      # Interactive icon button with hover animations
└── components/               # Bar components and popup views
    ├── Workspaces.qml        # Hyprland workspace indicators with wheel scrolling
    ├── Clock.qml             # Expandable calendar clock island
    ├── SystemPill.qml        # In-bar tray, audio, network & bluetooth controls
    └── popups/               # Dynamic Island content views
        ├── AudioPopup.qml    # Master sliders, sink switcher & app mixer
        ├── NetworkPopup.qml  # Wi-Fi network selector, Ethernet card & telemetry
        ├── BluetoothPopup.qml# Bluetooth power toggle, device scanner & pairing
        ├── NotificationPopup # Stacked notification cards with hover-pause timers
        └── TrayContextMenu   # Native context menu for system tray icons
```

---

## 🎛️ Multimedia Wheel Modes

The laptop/keyboard audio mute key (`XF86AudioMute`) functions as a mode switcher, cycling the volume wheel through three distinct modes:

| Mode | Trigger | Wheel Up | Wheel Down |
| :--- | :--- | :--- | :--- |
| **0. Volume** | `XF86AudioMute` (Cycle 0) | Volume Up (`wpctl +5%`) | Volume Down (`wpctl -5%`) |
| **1. Mouse Scrolling** | `XF86AudioMute` (Cycle 1) | Mouse Scroll Down (`ydotool`) | Mouse Scroll Up (`ydotool`) |
| **2. Window Switching** | `XF86AudioMute` (Cycle 2) | Focus Right Window | Focus Left Window |

*Each mode change sends an in-place notification with a 1.5s countdown and dedicated icon (`audio-volume-high`, `input-mouse`, `preferences-system-windows`).*

---

## ⌨️ Keybindings

*(Note: The `SUPER` key represents the Windows / Mod key)*

### Applications & Launchers
| Shortcut | Action | Application |
| :--- | :--- | :--- |
| `SUPER` + `Return` | Open Terminal | **Kitty** |
| `SUPER` + `Space` | Application Launcher | **Rofi** |
| `SUPER` + `V` | Clipboard History | **Cliphist** + **Rofi** |
| `SUPER` + `C` | Calculator | **Rofi Calc** |
| `SUPER` + `E` | File Manager | **Thunar** |
| `SUPER` + `M` | Power / Logout Menu | **Wlogout** |
| `SUPER` + `L` | Lock Screen | **Hyprlock** |

### Screenshots
| Shortcut | Action | Destination |
| :--- | :--- | :--- |
| `SUPER` + `Shift` + `S` | Select Region to Clipboard | Clipboard (`wl-copy`) |
| `ALT` + `Shift` + `S` | Select Region to File | `~/Pictures/Screenshots/` |
| `SUPER` + `O` | Fullscreen Screenshot | Clipboard (`wl-copy`) |

### Window Management & Workspaces
| Shortcut | Action |
| :--- | :--- |
| `SUPER` + `W` | Close active window |
| `SUPER` + `Q` | Toggle floating window |
| `SUPER` + `1` – `9` | Switch to workspace 1–9 |
| `SUPER` + `Shift` + `1` – `9` | Move active window to workspace 1–9 |
| `SUPER` + `S` | Toggle special scratchpad workspace |
| `SUPER` + `Shift` + `Q` | Move active window to special scratchpad |
| `SUPER` + `Mouse Scroll` | Cycle workspaces (`e+1` / `e-1`) |
| `SUPER` + `LMB Drag` | Move window |
| `SUPER` + `RMB Drag` | Resize window |

---

## 📦 Included Packages

| Package | Application | Description |
| :--- | :--- | :--- |
| `quickshell` | [Quickshell](https://quickshell.outfoxxed.me/) | Dynamic Island status bar, notification center & popups |
| `hypr` | [Hyprland](https://hyprland.org/) | Wayland compositor (Lua config), Hyprlock & Hypridle |
| `wallust` | [Wallust](https://codeberg.org/explosion-mental/wallust) | Dynamic color generation and application templates |
| `kitty` | [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal emulator |
| `rofi` | [Rofi-Wayland](https://github.com/lbonn/rofi) | App launcher, window switcher, and clipboard UI |
| `gtk` | GTK 3 & 4 | Glassmorphic theme overrides |
| `cliphist` | [Cliphist](https://github.com/sentriz/cliphist) | Wayland clipboard manager with image previews |
| `fish` | [Fish Shell](https://fishshell.com/) | Interactive shell configuration |
| `scripts` | Shell Scripts | Helpers for wallpapers (`wall.sh`), clipboard, etc. |
| `waypaper` | [Waypaper](https://github.com/anufrievroman/waypaper) | Graphical wallpaper manager |
| `wlogout` | [Wlogout](https://github.com/ArtsyMacaw/wlogout) | Power and session management menu |
| `uwsm` | [UWSM](https://github.com/Vladimir-csp/uwsm) | Universal Wayland Session Manager |
| `systemd` | Systemd | User session services |
| `waybar` | [Waybar](https://github.com/Alexays/Waybar) | Alternative status bar configuration |

---

## ⚙️ Prerequisites

Ensure the following tools and packages are installed:

- **Core & Compositor:** `hyprland`, `hyprland-lua`, `uwsm`, `stow`
- **Shell & UI:** `quickshell`, `kitty`, `rofi-wayland`, `wlogout`, `hyprlock`, `hypridle`
- **Theming & Wallpaper:** `wallust`, `waypaper`, `awww` (or `swww`), `papirus-icon-theme`
- **Audio & Media:** `pipewire`, `wireplumber`, `playerctl`, `brightnessctl`
- **Clipboard & Tools:** `cliphist`, `wl-clipboard`, `wtype`, `slurp`, `grim`, `ydotool`

---

## 🚀 Installation

These dotfiles are managed with **[GNU Stow](https://www.gnu.org/software/stow/)**, symlinking configuration folders directly into your home directory:

```bash
# 1. Clone the repository
git clone https://github.com/DerpBoy77/dot-files.git ~/dot-files
cd ~/dot-files

# 2. Stow all packages
stow cliphist fish gtk hypr kitty quickshell rofi scripts systemd uwsm wallust waypaper wlogout

# Or stow individual packages as needed
stow quickshell hypr kitty
```

To remove symlinks for any package:
```bash
stow -D quickshell
```
