-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ◈ KEYBINDINGS (da backup ilyamiro, tradotti in Lua + quickshell end-4)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"

-- ───────── Edit user keybinds ─────────
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"})

-- ───────── Applicazioni ─────────
hl.bind("SUPER + Q", hl.dsp.exec_cmd("foot"), { description = "App: Terminal (foot)" })
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus"), { description = "App: File manager" })
hl.bind("SUPER + R", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/reload.sh"), { description = "App: Reload config" })
hl.bind("SUPER + C", hl.dsp.global("quickshell:overviewClipboardToggle"), { description = "App: Clipboard" })
hl.bind("ALT + Space", hl.dsp.global("quickshell:searchToggleRelease"), { description = "App: App launcher" })
hl.bind("SUPER + ALT + Space", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "App: Wallpaper" })
hl.bind("SUPER + ALT + Space", hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/colors/switchwall.sh"))
hl.bind("SUPER + SHIFT + T", hl.dsp.global("quickshell:focustimeToggle"), { description = "App: Focus time" })

-- ───────── Finestre ─────────
hl.bind("CTRL + SHIFT + W", hl.dsp.window.close(), { description = "Window: Kill active" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Toggle floating" })
hl.bind("SUPER + SHIFT + Left", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -50 0"), { repeating = true, description = "Window: Resize left" })
hl.bind("SUPER + SHIFT + Right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 50 0"), { repeating = true, description = "Window: Resize right" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -50"), { repeating = true, description = "Window: Resize up" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 50"), { repeating = true, description = "Window: Resize down" })
hl.bind("SUPER + CTRL + Left", hl.dsp.window.move({ direction = "l" }), { description = "Window: Move left" })
hl.bind("SUPER + CTRL + Right", hl.dsp.window.move({ direction = "r" }), { description = "Window: Move right" })
hl.bind("SUPER + CTRL + Up", hl.dsp.window.move({ direction = "u" }), { description = "Window: Move up" })
hl.bind("SUPER + CTRL + Down", hl.dsp.window.move({ direction = "d" }), { description = "Window: Move down" })
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }), { description = "Window: Focus left" })
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }), { description = "Window: Focus right" })
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }), { description = "Window: Focus up" })
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }), { description = "Window: Focus down" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("hyprctl keyword general:layout $(hyprctl getoption general:layout -j | jq -r 'if .str == \"master\" then \"dwindle\" else \"master\" end')"), { description = "Window: Toggle layout" })

-- ───────── Monitor ─────────
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_next_monitor.sh"), { description = "Monitor: Focus next" })
hl.bind("ALT + Tab", hl.dsp.focus({ direction = "r" }), { description = "Monitor: Focus right" })

-- ───────── Workspace ─────────
for i = 1, 10 do
    local ws = i % 10
    hl.bind("SUPER + " .. ws, function()
        hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
    end, { description = "Workspace: Focus " .. i })
end
for i = 1, 10 do
    local ws = i % 10
    hl.bind("SUPER + SHIFT + " .. ws, function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = true }))
    end, { description = "Workspace: Move to " .. i })
end

-- ───────── Screenshot ─────────
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"), { description = "Screenshot: Region" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --edit"))
hl.bind("F9", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full --edit"), { locked = true, description = "Screenshot: Full" })

-- ───────── Session ─────────
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Session: Lock" })

-- ───────── Keyboard layout ─────────
hl.bind("SUPER + Space", hl.dsp.exec_cmd("hyprctl switchxkblayout drunkdeer-drunkdeer-a75-ansi next"), { description = "Keyboard: Toggle IT/EN" })
