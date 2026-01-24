#!/bin/bash

# 1. Set the wallpaper variable
img="$1"

# 2. Set the wallpaper using swww (or awww)
awww img "$img" --transition-type grow --transition-pos 0.854,0.977 --transition-step 90

# 3. Generate Colors using Pywal
# -i: Input image
# -n: Skip setting the wallpaper (swww handles it better)
wal -i "$img" -n

# 4. Copy the wallpaper to a fixed location for Hyprlock to find
cp "$img" ~/.cache/current_wallpaper.png

# 5. Reload Waybar to apply colors
pkill waybar && hyprctl dispatch exec waybar

# 6. Reload Swaync/Mako (Notification daemons) if you use them
# swww handles the background, but we need to reload other apps that don't auto-reload
# pywal automatically reloads kitty and rofi usually.

current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")

# 2. Switch to a dummy theme (HighContrast is usually safe/installed)
gsettings set org.gnome.desktop.interface gtk-theme "HighContrast"

# 3. Switch back to your original theme
# This rapid switch forces all apps to re-read ~/.config/gtk-3.0/gtk.css
gsettings set org.gnome.desktop.interface gtk-theme "$current_theme"
