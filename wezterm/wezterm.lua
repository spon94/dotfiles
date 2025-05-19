local wezterm = require("wezterm")

local config = wezterm.config_builder()
local launch_menu = {}
config.launch_menu = launch_menu

-- Initialize Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local opacity = 1
local transparent_bg = "rgba(22, 24, 26, " .. opacity .. ")"

--- Get the current operating system
--- @return "windows"| "linux" | "macos"
local function get_os()
    local bin_format = package.cpath:match("%p[\\|/]?%p(%a+)")
    if bin_format == "dll" then
        return "windows"
    elseif bin_format == "so" then
        return "linux"
    end

    return "macos"
end

local host_os = get_os()

-- Configuration Theme 
config.color_scheme = "Dracula (Official)"
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"

-- Color Configuration
config.colors = require("cyberdream")
config.force_reverse_video_cursor = true

-- Window Configuration
config.initial_rows = 45
config.initial_cols = 180
config.window_decorations = "RESIZE"
config.window_background_opacity = opacity
config.window_background_image = (os.getenv("WEZTERM_CONFIG_FILE") or ""):gsub("wezterm.lua", "bg-blurred.png")
config.window_close_confirmation = "NeverPrompt"
config.win32_system_backdrop = "Acrylic"

-- Performance Settings
config.max_fps = 144
config.animation_fps = 60
config.cursor_blink_rate = 250

-- Tab Bar Configuration
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.use_fancy_tab_bar = false
config.colors.tab_bar = {
    background = config.window_background_image and "rgba(0, 0, 0, 0)" or transparent_bg,
    new_tab = { fg_color = config.colors.background, bg_color = config.colors.brights[6] },
    new_tab_hover = { fg_color = config.colors.background, bg_color = config.colors.foreground },
}

-- Tab Formatting
wezterm.on("format-tab-title", function(tab, _, _, _, hover)
    local background = config.colors.brights[1]
    local foreground = config.colors.foreground

    if tab.is_active then
        background = config.colors.brights[7]
        foreground = config.colors.background
    elseif hover then
        background = config.colors.brights[8]
        foreground = config.colors.background
    end

    local title = tostring(tab.tab_index + 1)
    return {
        { Foreground = { Color = background } },
        { Text = "█" },
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = title },
        { Foreground = { Color = background } },
        { Text = "█" },
    }
end)

-- Configuration Fonts
config.font =
  wezterm.font('JetBrains Mono', { weight = 'Bold', italic = false })
  config.font_size = 15.0

-- Configuration launch program
config.default_prog = { "powershell.exe" }

-- Configuration ssh
local ssh_cmd = {"ssh"}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    ssh_cmd = {"powershell.exe", "ssh"}

    table.insert(
        launch_menu,
        {
            label = "Bash",
            args = {"C:/Program Files/Git/bin/bash.exe", "-li"}
        }
    )

    table.insert(
        launch_menu,
        {
            label = "CMD",
            args = {"cmd.exe"}
        }
    )

    table.insert(
        launch_menu,
        {
            label = "PowerShell",
            args = {"powershell.exe", "-NoLogo"}
        }
    )

end

local ssh_config_file = wezterm.home_dir .. "/.ssh/config"
local f = io.open(ssh_config_file)
if f then
    local line = f:read("*l")
    while line do
        if line:find("Host ") == 1 then
            local host = line:gsub("Host ", "")
            local args = {}
            for i,v in pairs(ssh_cmd) do
                args[i] = v
            end
            args[#args+1] = host
            table.insert(
                launch_menu,
                {
                    label = "SSH " .. host,
                    args = args,
                }
            )
            -- default open vm
            if host == "vm" then
                config.default_prog = {"powershell.exe", "ssh", "vm"}
            end
        end
        line = f:read("*l")
    end
    f:close()
end


wezterm.on( "update-right-status", function(window)
    local date = wezterm.strftime("%Y-%m-%d %H:%M:%S   ")
    window:set_right_status(
        wezterm.format(
            {
                {Text = date}
            }
        )
    )
end)

wezterm.on('format-tab-title', function (tab, _, _, _, _)
    return {
        { Text = ' ' .. tab.tab_index + 1 .. ' ' },
    }
end)

wezterm.on("gui-startup", function()
  local tab, pane, window = wezterm.mux.spawn_window{}
  window:gui_window():maximize()
end)

local window_min = ' 󰖰 '
local window_max = ' 󰖯 '
local window_close = ' 󰅖 '
config.tab_bar_style = {
    window_hide = window_min,
    window_hide_hover = window_min,
    window_maximize = window_max,
    window_maximize_hover = window_max,
    window_close = window_close,
    window_close_hover = window_close,
}

config.window_decorations="INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
config.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}


-- OS-Specific Overrides
if host_os == "linux" then
    emoji_font = "Noto Color Emoji"
    config.default_prog = { "zsh" }
    config.front_end = "WebGpu"
    config.window_background_image = os.getenv("HOME") .. "/.config/wezterm/bg-blurred.png"
    config.window_decorations = nil -- use system decorations
end

return config
