--[[ -- RilCritch's Wezterm Configuration -- ]]--


--[[ Initial Config Setup ]]-- {{{

-- Wezterm API
local wezterm require("wezterm")

-- Initialize the config table
local config = {}
if wezterm.config_builder then 
  config = wezterm.config_builder()
end

-- Set the error mode to strict
config:set_strict_mode(true)

--}}}
