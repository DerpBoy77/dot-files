#!/usr/bin/env bash
# HDR Toggle & Brightness Script for Hyprland 0.56.2 (Lua config) & Dell Alienware AW2726DM
# Dynamically switches between calibrated QD-OLED HDR and standard sRGB, and adjusts SDR luminance.

set -euo pipefail

TARGET_OUTPUT="DP-1"
CURRENT_PRESET=$(hyprctl monitors -j | jq -r --arg out "$TARGET_OUTPUT" '.[] | select(.name == $out) | .colorManagementPreset')

enable_hdr() {
    hyprctl eval 'hl.monitor({ output = "DP-1", mode = "2560x1440@240", position = "auto", scale = "auto", bitdepth = 10, cm = "hdredid", supports_wide_color = 1, supports_hdr = 1, min_luminance = 0.0, max_luminance = 409, max_avg_luminance = 204, sdrbrightness = .9, sdrsaturation = 1, sdr_max_luminance = 204, sdr_min_luminance = 0.0 })' > /dev/null
    notify-send -i video-display -t = "Display Profile" "HDR Enabled (AW2726DM QD-OLED Calibrated)"
}

disable_hdr() {
    hyprctl eval 'hl.monitor({ output = "DP-1", mode = "2560x1440@240", position = "auto", scale = "auto", bitdepth = 10, cm = "srgb", sdrbrightness = 1.0, sdrsaturation = 1.0, min_luminance = 0.0, sdr_min_luminance = 0.0 })' > /dev/null
    notify-send -i video-display -t 4000 "Display Profile" "SDR Enabled (Standard sRGB Mode)"
}

set_brightness() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        local cur_bright
        cur_bright=$(hyprctl monitors -j | jq -r --arg out "$TARGET_OUTPUT" '.[] | select(.name == $out) | .sdrBrightness // 1.0')
        echo "Current SDR Brightness: $cur_bright"
        return 0
    fi

    local cur_bright
    cur_bright=$(hyprctl monitors -j | jq -r --arg out "$TARGET_OUTPUT" '.[] | select(.name == $out) | .sdrBrightness // 1.0')
    local new_bright
    if [[ "$target" =~ ^[+-] ]]; then
        new_bright=$(python3 -c "print(max(0.5, min(2.5, round($cur_bright + ($target), 2))))")
    else
        new_bright=$(python3 -c "print(max(0.5, min(2.5, round(float('$target'), 2))))")
    fi

    hyprctl eval "hl.monitor({ output = \"DP-1\", mode = \"2560x1440@240\", position = \"auto\", scale = \"auto\", bitdepth = 10, cm = \"hdredid\", supports_wide_color = 1, supports_hdr = 1, min_luminance = 0.0, max_luminance = 409, max_avg_luminance = 204, sdrbrightness = $new_bright, sdrsaturation = 1, sdr_max_luminance = 204, sdr_min_luminance = 0.0 })" > /dev/null
    notify-send -i video-display -t 2000 "HDR Brightness" "SDR Luminance: ${new_bright}"
    echo "SDR Brightness set to $new_bright"
}

case "${1:-toggle}" in
    on|enable)
        enable_hdr
        ;;
    off|disable)
        disable_hdr
        ;;
    status)
        echo "Current color management preset: $CURRENT_PRESET"
        ;;
    brightness|bright|b)
        set_brightness "${2:-}"
        ;;
    toggle)
        if [[ "$CURRENT_PRESET" == "hdredid" || "$CURRENT_PRESET" == "hdr" ]]; then
            disable_hdr
        else
            enable_hdr
        fi
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|status|brightness <value|+delta|-delta>]"
        echo "Examples:"
        echo "  $0 brightness 1.25    # Set brightness multiplier to 1.25"
        echo "  $0 brightness +0.05   # Step brightness up by 0.05"
        echo "  $0 brightness -0.05   # Step brightness down by 0.05"
        exit 1
        ;;
esac
