source /usr/share/cachyos-fish-config/cachyos-config.fish

if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec start-hyprland
    end
end

function fish_greeting
    if not set -q VSCODE_INJECTION
        fastfetch
    end
end
