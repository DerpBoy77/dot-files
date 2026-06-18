local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi -show drun"
local calculator  = "rofi -show calc -modi calc"



local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(calculator))
hl.bind(mainMod .. " + Q", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("pkill -x rofi || " .. menu))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))

-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.config/scripts/clip.sh"))

-- Lock screen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Screenshot a region to clipboard (The most common use)
hl.bind(mainMod .. " + SHIFT + S",
    hl.dsp.exec_cmd("bash -c 'geom=$(slurp) && sleep 0.2 && grim -g \"$geom\" - | wl-copy'"))

-- Screenshot a region and save to file
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +'%s_grim.png')"))

-- Screenshot the whole screen to clipboard
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
-- Create a variable to track the current mode
-- 0 = Volume, 1 = Web Scrolling, 2 = Window Switching
local wheel_mode = 0

-- Pressing the wheel cycles through the 3 modes
hl.bind("XF86AudioMute", function()
    -- Add 1 to the mode. The "% 3" makes it wrap back to 0 after it hits 2.
    wheel_mode = (wheel_mode + 1) % 3

    -- Send a notification so you know which mode is active
    if wheel_mode == 0 then
        hl.dispatch(hl.dsp.exec_cmd("notify-send -t 1500 'Wheel Mode' 'Volume'"))
    elseif wheel_mode == 1 then
        hl.dispatch(hl.dsp.exec_cmd("notify-send -t 1500 'Wheel Mode' 'Mouse Scrolling'"))
    elseif wheel_mode == 2 then
        hl.dispatch(hl.dsp.exec_cmd("notify-send -t 1500 'Wheel Mode' 'Window Switching'"))
    end
end, { locked = true })


-- Wheel Up
hl.bind("XF86AudioRaiseVolume", function()
    if wheel_mode == 1 then
        -- Mode 1: Mouse scroll down
        hl.dispatch(hl.dsp.exec_cmd("ydotool mousemove -w -- 0 1"))
    elseif wheel_mode == 2 then
        -- Mode 2: Global focus (works in Dwindle AND Scrolling)
        hl.dispatch(hl.dsp.focus({ direction = "r" }))
    else
        -- Mode 0: Turn volume up
        hl.dispatch(hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
    end
end, { locked = true, repeating = true })


-- Wheel Down
hl.bind("XF86AudioLowerVolume", function()
    if wheel_mode == 1 then
        -- Mode 1: Mouse scroll up
        hl.dispatch(hl.dsp.exec_cmd("ydotool mousemove -w -- 0 -1"))
    elseif wheel_mode == 2 then
        -- Mode 2: Global focus (works in Dwindle AND Scrolling)
        hl.dispatch(hl.dsp.focus({ direction = "l" }))
    else
        -- Mode 0: Turn volume down
        hl.dispatch(hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
    end
end, { locked = true, repeating = true })

hl.bind(mainMod .. " + XF86AudioRaiseVolume", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + XF86AudioLowerVolume", hl.dsp.focus({ workspace = "e-1" }))

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- 1. SWAP COLUMNS: Move the entire active column left or right
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.layout("swapcol r"))

-- 2. SMART MERGING: Move a window into the previous/next column, or expel it if it's currently stacked
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.layout("consume_or_expel prev"))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.layout("consume_or_expel next"))

-- 3. PROMOTE: Break a stacked window out into its own brand new column
hl.bind(mainMod .. " + P", hl.dsp.layout("promote"))

-- 4. PANNING: Scroll the view of the layout left/right without changing your active window
hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.layout("move -col"))

-- Cycle column width: 33% -> 50% -> 66% -> 100% -> back to 33%
hl.bind(mainMod .. " + ALT + W", hl.dsp.layout("colresize +conf"))
