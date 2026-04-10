#!/usr/bin/env bash

TMP_DIR="/tmp/cliphist-previews"
mkdir -p "$TMP_DIR"

# 1. Asynchronously prune old caches (no delay to Rofi)
(
    declare -A valid_ids
    while IFS=$'\t' read -r id _; do
        [ -n "$id" ] && valid_ids["$id"]=1
    done < <(cliphist list)

    shopt -s nullglob
    for img in "$TMP_DIR"/*.png; do
        id=${img##*/}
        id=${id%.png}
        [ -n "${valid_ids[$id]}" ] || rm -f -- "$img"
    done
) &

# 2. Build the Rofi list
# We use IFS=$'\t' to instantly split the ID and content natively in memory.
# This gives us awk-like speed without the subshell quoting bugs.
SELECTED=$(
    while IFS=$'\t' read -r id content; do
        [ -n "$id" ] || continue
        line=$(printf '%s\t%s' "$id" "$content")

        if [[ "$content" == *"[[ binary data"* ]]; then
            image_path="$TMP_DIR/$id.png"
            
            # If the image isn't cached, generate it safely
            if [ ! -f "$image_path" ]; then
                # Reconstruct the exact string with the tab character for cliphist
                printf '%s\n' "$line" | cliphist decode > "$image_path" 2>/dev/null
                
                # Check if it's a real image, delete if it's a copied file/junk
                if [ ! -s "$image_path" ] || ! file -b --mime-type "$image_path" | grep -q "^image/"; then
                    rm -f -- "$image_path"
                fi
            fi
            
            # If it passed the check and exists, attach the icon flag
            if [ -f "$image_path" ]; then
                printf '%s\0icon\x1f%s\n' "$line" "$image_path"
            else
                printf '%s\n' "$line"
            fi
        else
            # It's just text, output it normally
            printf '%s\n' "$line"
        fi
    done < <(cliphist list) | rofi -dmenu -show-icons -p "Clipboard" -theme-str 'listview { lines: 5; } element-icon { size: 2.5em; }'
)

# 3. Paste Logic
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Cleanly decode the selected item into wl-copy
printf '%s\n' "$SELECTED" | cliphist decode | wl-copy

# Give Hyprland a tiny moment to close Rofi and restore window focus
sleep 0.15

# Send the paste shortcut via wtype
wtype -M ctrl v -m ctrl