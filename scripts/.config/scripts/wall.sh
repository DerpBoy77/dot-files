#!/bin/bash

# 1. Set the wallpaper variable
img="$1"

# 2. Set the wallpaper using swww
awww img "$img" --transition-type grow --transition-pos 0.854,0.977 --transition-step 90

# 3. Generate Colors using Wallust
wallust run "$img"

# 4. Copy the wallpaper to a fixed location for Hyprlock to find
cp "$img" ~/.cache/current_wallpaper.png

# 5. Reload Waybar to apply colors
pkill waybar && hyprctl dispatch exec waybar

