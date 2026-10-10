local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.cache/wallust/?.lua"
local c = require("colors")

-- Helper to adjust hex alpha in wallust colors (e.g. "ff" -> "aa" for ~66% opacity on OLED)
local function alpha(color_str, a)
  return color_str and (color_str:gsub("ff%)$", a .. ")")) or color_str
end


hl.monitor({
  output              = "DP-1",
  mode                = "2560x1440@240",
  position            = "auto",
  scale               = "auto",
  bitdepth            = 10,
  cm                  = "hdredid",
  supports_wide_color = 1,
  supports_hdr        = 1,
  min_luminance       = 0.0,
  max_luminance       = 409,
  max_avg_luminance   = 204,
  sdrbrightness       = .9,
  sdrsaturation       = 1,
  sdr_max_luminance   = 204,
  sdr_min_luminance   = 0.0
})

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
  local autostart_cmds = {
    "quickshell",
    "awww-daemon",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
    "hypridle",
    "systemctl --user start hyprpolkitagent",
    "udiskie",
    "[workspace special:magic silent] thunar",
    "sleep 2 && easyeffects --service-mode -w",
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

    border_size       = 2,

    col               = {
      active_border   = alpha(c.color4, "aa"),
      inactive_border = "rgba(00000000)",
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
      xray              = false,
      popups            = true,
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
    vrr                     = 2,    -- 1 = on, 2 = fullscreen only (FreeSync on AW2726DM 240Hz)
    key_press_enables_dpms  = true
  },

  render = {
    direct_scanout       = 1,          -- Direct scanout for reduced latency in fullscreen games
    cm_enabled           = true,       -- Explicitly enable color management pipeline
    cm_auto_hdr          = 2,          -- Automatic HDR tagging for HDR-capable applications
    cm_sdr_eotf          = "gamma22",  -- Pure power 2.2 curve; eliminates washed out gray shadows
    keep_unmodified_copy = 2,          -- Preserves untransformed sRGB buffer for screenshots/streaming
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
  match = { class = "com.microsoft.VSCode" },
  opacity = 0.85
})

hl.window_rule({
  name = "sushi_quicklook",
  match = {
    class = "^(org.gnome.NautilusPreviewer)$"
  },
  float = true,
  center = true,
  dim_around = true,
  animation = "popin",
  opacity = "0.9 0.9" -- active and inactive opacity
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

hl.layer_rule({
  name = "quickshell",
  blur = true,
  ignore_alpha = 0.5,
  blur_popups = true,
  match = {
    namespace = "quickshell"
  }
})

hl.layer_rule({
  name = "wlogout",
  blur = true,
  ignore_alpha = 0.5,
  match = {
    namespace = "logout_dialog"
  }
})

hl.workspace_rule({
  workspace = "5",
  layout = "scrolling",
})

-- OLED Burn-in Protection: disable borders when a single tiled window is alone or fullscreen
hl.window_rule({
  name        = "oled_solitary_no_border",
  match       = { workspace = "w[tv1]", float = false },
  border_size = 0,
})

hl.window_rule({
  name        = "oled_fullscreen_no_border",
  match       = { fullscreen = true },
  border_size = 0,
})

hl.window_rule({
  name="mpv",
  match ={namespace="mpv"},
  no_vrr=true
})