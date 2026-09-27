-- Follows the desktop theme picked with `mars-theme` (SUPER+. -> Theme), so
-- the editor always matches the rest of the desktop.
--
-- The desktop saves its choice in ~/.local/state/mars/theme.env as
--   THEME=gruvbox-material-<mode>-<background>-<foreground>   (or gruvmoon)
-- which maps one-to-one onto gruvbox-material's own options. `mars-theme`
-- calls M.apply() in every running Neovim after a switch.
local M = {}

local STATE_FILE = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
  .. "/mars/theme.env"

-- GruvMoon is the desktop's hand-kept palette; its closest upstream variant.
local GRUVMOON = { mode = "dark", background = "medium", foreground = "material" }

local function saved_theme_id()
  local file = io.open(STATE_FILE, "r")
  if not file then
    return nil
  end
  local id
  for line in file:lines() do
    id = line:match("^THEME=(.+)$") or id
  end
  file:close()
  return id
end

-- { mode, background, foreground } for the saved desktop theme.
function M.variant()
  local id = saved_theme_id()
  local mode, background, foreground = (id or ""):match("^gruvbox%-material%-(%a+)%-(%a+)%-(%a+)$")
  if mode then
    return { mode = mode, background = background, foreground = foreground }
  end
  return GRUVMOON
end

function M.apply()
  local v = M.variant()
  vim.o.background = v.mode
  vim.g.gruvbox_material_background = v.background
  vim.g.gruvbox_material_foreground = v.foreground
  vim.cmd.colorscheme("gruvbox-material")
end

return M
