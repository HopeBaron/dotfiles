-- TUI theme switcher (:Themery or <leader>uc). Live preview, and persists
-- the chosen variant across restarts on its own -- no custom picker needed.
-- Gruvbox Material has 3 backgrounds x 3 foregrounds; each entry sets both
-- via a `before` hook, then applies the colorscheme. "medium / material"
-- comes first, so it's the fallback default on a fresh install with nothing
-- persisted yet -- matching this machine's desktop-wide theme.
return {
  {
    "zaldih/themery.nvim",
    lazy = false, -- must load eagerly: persistence restores on require, not on a command
    priority = 900,
    keys = {
      { "<leader>uc", "<cmd>Themery<cr>", desc = "Pick colorscheme variant" },
    },
    config = function()
      local variants = {}
      for _, bg in ipairs({ "medium", "hard", "soft" }) do
        for _, fg in ipairs({ "material", "mix", "original" }) do
          table.insert(variants, {
            name = bg .. " / " .. fg,
            colorscheme = "gruvbox-material",
            before = string.format(
              [[
                vim.g.gruvbox_material_background = "%s"
                vim.g.gruvbox_material_foreground = "%s"
              ]],
              bg,
              fg
            ),
          })
        end
      end

      require("themery").setup({
        themes = variants,
        livePreview = true,
      })
    end,
  },
}
