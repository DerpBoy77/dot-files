-- =======================================================
-- FADE BEZIERS (Kept because springs break opacity fades)
-- =======================================================
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })


-- =======================================================
-- SPRING PHYSICS (mass, stiffness, dampening)
-- =======================================================

-- 1. Ultra-Snap: Extremely fast, high tension, high friction. Zero bounce. Great for closing things.
hl.curve("ultra_snap", { type = "spring", mass = 1, stiffness = 400, dampening = 38 })

-- 2. Smooth-Snap: Fast, but with a tiny micro-millisecond of settling so it doesn't feel robotic. Perfect for opening and moving windows.
hl.curve("smooth_snap", { type = "spring", mass = 1, stiffness = 450, dampening = 35 })

-- 3. Workspace-Snap: Slightly lower tension so swiping workspaces doesn't give you whiplash, but tightly dampened so it doesn't wobble.
hl.curve("workspace_snap", { type = "spring", mass = 1, stiffness = 400, dampening = 34 })


-- =======================================================
-- ANIMATION BINDINGS
-- =======================================================
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })

-- Windows
hl.animation({ leaf = "windows", enabled = true, speed = 1, spring = "smooth_snap" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "smooth_snap", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, spring = "ultra_snap", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "smooth_snap" })

-- Fades (Must remain Beziers)
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })

-- Layers (Waybar, Rofi, Polkit, Sushi, etc)
hl.animation({ leaf = "layers", enabled = true, speed = 1, spring = "smooth_snap" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1, spring = "smooth_snap", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1, spring = "ultra_snap", style = "fade" })

-- Workspaces
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "workspace_snap", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1, spring = "workspace_snap", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1, spring = "workspace_snap", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 1, spring = "workspace_snap", style = "slidevert -100%" })
hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 1,
    spring = "workspace_snap",
    style =
    "slidevert -100%"
})
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1, spring = "ultra_snap", style = "slidevert -100%" })

-- Zoom Factor
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 1, spring = "workspace_snap" })
