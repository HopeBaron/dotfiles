return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000, -- paint before any other plugin draws
    config = function()
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      -- Mode/background/foreground come from the desktop theme (mars-theme),
      -- not from here -- see lua/mars/theme.lua.
      require("mars.theme").apply()
    end,
  },
}
