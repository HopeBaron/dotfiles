return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000, -- load before themery (900), so this default is what
                      -- themery's own persistence overrides, not the other
                      -- way round. Themery only restores a PERSISTED choice
                      -- on startup -- on a genuinely fresh install with no
                      -- state file yet, it applies nothing at all, so this
                      -- default is what actually paints the screen the
                      -- first time.
    config = function()
      -- Matches this machine's desktop-wide theme (dotfiles' theme/palette.sh).
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
}
