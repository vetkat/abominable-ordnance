std = "lua52"
max_line_length = 100
-- .lua, .luarocks and .install hold the Lua that CI installs in the
-- workspace. docs/archive holds old chat logs.
exclude_files = {
  "spec/fixtures/**", "node_modules/**", "build/**", "docs/archive/**",
  ".lua/**", ".luarocks/**", ".install/**",
}

-- Factorio's Lua environment. The game provides these, not Lua.
local factorio = {
  "data", "mods", "settings", "defines", "game", "script", "prototypes",
  "remote", "commands", "rendering", "log", "serpent", "table_size",
  "helpers",
}

-- storage is the mod's saved table, and Factorio adds table.deepcopy.
-- Mods write to both.
local factorio_writable = { "storage", "table" }

local stage = { read_globals = factorio, globals = factorio_writable }
for _, path in ipairs({
  "data.lua", "data-updates.lua", "data-final-fixes.lua", "settings.lua",
  "settings-updates.lua", "settings-final-fixes.lua", "control.lua", "prototypes",
}) do
  files[path] = stage
end

-- core/ gets no Factorio globals. That is the architecture rule.

files["spec"] = { std = "+busted" }
