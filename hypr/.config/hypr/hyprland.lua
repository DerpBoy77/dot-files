local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.cache/wallust/?.lua"
local c = require("colors")


hl.monitor({
  output   = "",
  mode     = "1920x1080@144",
  position = "auto",
  scale    = "auto",
})

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  local autostart_cmds = {
    "waybar",
    "awww-daemon",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
    "nm-applet --indicator",
    "blueman-applet",
    "hypridle",
    "systemctl --user start hyprpolkitagent",
    "udiskie",
    "[workspace special:magic silent] thunar",
  }

  for _, cmd in ipairs(autostart_cmds) do
    hl.exec_cmd(cmd)
  end
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  general = {
    gaps_in           = 5,
    gaps_out          = 15,

    border_size       = 3,

    col               = {
      active_border   = c.color2,
      inactive_border = c.color8,
    },

    -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border  = false,

    -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
    allow_tearing     = false,

    layout            = "dwindle",
    no_focus_fallback = true,
  },

  decoration = {
    rounding              = 10,
    rounding_power        = 2,

    -- Change transparency of focused and unfocused windows
    active_opacity        = 1.0,
    inactive_opacity      = 1.0,

    shadow                = {
      enabled      = true,
      range        = 4,
      render_power = 3,
      color        = c.background,
    },

    blur                  = {
      enabled           = true,
      size              = 6,
      passes            = 2,
      vibrancy          = 0.1696,
      new_optimizations = true,
      ignore_opacity    = true,
      xray              = false
    },

    border_part_of_window = false
  },

  animations = {
    enabled = true,
  },
})

require("hyprland.animations")

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
  dwindle = {
    preserve_split = true, -- You probably want this
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
  master = {
    new_status = "master",
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
  scrolling = {
    fullscreen_on_one_column = true,
  },
})

----------------
----  MISC  ----
----------------

hl.config({
  misc = {
    force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
    disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    vrr                     = 2
  },
})


---------------
---- INPUT ----
---------------

hl.config({
  input = {
    kb_layout     = "us",
    kb_variant    = "",
    kb_model      = "",
    kb_options    = "",
    kb_rules      = "",

    follow_mouse  = 1,

    sensitivity   = 0.25, -- -1.0 - 1.0, 0 means no modification.
    accel_profile = "flat",

    touchpad      = {
      natural_scroll = false,
    },
  },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

require("hyprland.keybinds")

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local suppressMaximizeRule = hl.window_rule({
  -- Ignore maximize requests from all apps. You'll probably like this.
  name           = "suppress-maximize-events",
  match          = { class = ".*" },

  suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})

hl.window_rule({
  name = "vsCode",
  match = { class = "code" },
  opacity = 0.875,
})

hl.layer_rule({
  name = "rofi",
  animation = "popin",
  blur = true,
  ignore_alpha = 0,
  dim_around = true,
  match = {
    namespace = "rofi"
  }
})

hl.workspace_rule({
  workspace = "5",
  layout = "scrolling",
})
