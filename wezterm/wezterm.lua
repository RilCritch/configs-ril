--[[ -- RilCritch's Wezterm Configuration -- ]]--
-- 
-- The init file for my wezterm configuration. 
-- The goal is to keep this modular from the start


--[[ Initial Config Setup ]]--

-- Wezterm API
local wezterm = require("wezterm")

-- Initialize the config table
local config = {}
if wezterm.config_builder then 
  config = wezterm.config_builder()
end

-- Set the error mode to strict
config:set_strict_mode(true)


--[[ Config Modules ]]--

-- Require modules
local conf = require("conf")

-- Merge modules

--[[ Return Config Table ]]--
return config


-- vim:fileencoding=utf-8:foldmethod=marker
