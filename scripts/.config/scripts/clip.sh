#!/usr/bin/env bash

TMP_DIR="/tmp/cliphist-previews"
mkdir -p "$TMP_DIR"

# ---------------------------------------------------------
# 1. Asynchronously prune old caches in background
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# 2. Read full entries into memory array
# ---------------------------------------------------------
mapfile -t RAW_LINES < <(cliphist list)
[ ${#RAW_LINES[@]} -eq 0 ] && exit 0

# ---------------------------------------------------------
# 3. Build Rofi list (Compact Container, 3 Large Rows, No IDs)
# ---------------------------------------------------------
INDEX=$(
    for line in "${RAW_LINES[@]}"; do
        IFS=$'\t' read -r id content <<< "$line"
        [ -n "$id" ] || continue

        if [[ "$content" == *"[[ binary data"* ]]; then
            image_path="$TMP_DIR/$id.png"
            
            if [ ! -f "$image_path" ]; then
                printf '%s\n' "$line" | cliphist decode > "$image_path" 2>/dev/null
                
                if [ ! -s "$image_path" ] || ! file -b --mime-type "$image_path" | grep -q "^image/"; then
                    rm -f -- "$image_path"
                fi
            fi
            
            if [ -f "$image_path" ]; then
                printf '%s\0icon\x1f%s\n' "$content" "$image_path"
            else
                printf '%s\n' "$content"
            fi
        else
            printf '%s\n' "$content"
        fi
    done | rofi -dmenu -show-icons -format i -p "Clipboard" \
        -theme-str '
            listview { 
                lines: 5; 
                fixed-height: true; 
                spacing: 4px; 
            } 
            element { 
                padding: 4px 10px; 
                spacing: 12px; 
                border-radius: 8px; 
            } 
            element-icon { 
                size: 3.4em; 
                border-radius: 6px; 
            } 
            element-text { 
                vertical-align: 0.5; 
            }
        '
)

# ---------------------------------------------------------
# 4. Decode Selected Index to Clipboard & Paste
# ---------------------------------------------------------
if [ -z "$INDEX" ]; then
    exit 0
fi

SELECTED_LINE="${RAW_LINES[$INDEX]}"

if [ -n "$SELECTED_LINE" ]; then
    printf '%s\n' "$SELECTED_LINE" | cliphist decode | wl-copy
    
    sleep 0.15
    wtype -M ctrl -M shift v -m shift -m ctrl
fi