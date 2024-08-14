-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config = {
  default_cursor_style = "BlinkingBlock",
  -- font = wezterm.font("Hack Nerd Font", { weight = 'Bold' }),
  font = wezterm.font("JetBrains Mono", { weight = 'Bold' }),
  font_size = 15,
  enable_tab_bar = false,
  window_decorations = "RESIZE",
  window_background_opacity = 0.7,
  macos_window_background_blur = 10,
  color_scheme = "Nord (Gogh)",
  background = {
    {
      source = {
        File = "/Users/" .. os.getenv("USER") .. "/Dev/dotfiles/terminal-backgrounds/backgrounds/gradient-fire-ice.png",
      },
      hsb = {
        hue = 1.0,
        saturation = 1.02,
        brightness = 0.25,
      },
      opacity = .8,
      -- attachment = { Parallax = 0.3 },
      -- width = "100%",
      -- height = "100%",
    },
    {
      source = {
        Color = "#282c35",
      },
      width = "100%",
      height = "100%",
      opacity = 0.55,
    },
  },
}

-- and finally, return the configuration to wezterm
return config
