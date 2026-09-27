return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          -- "auto" reads the active colorscheme, so a desktop theme switch
          -- (lua/mars/theme.lua) re-themes the statusline too, without
          -- hardcoding "gruvbox-material" here and needing to keep them in sync.
          theme = "auto",
          globalstatus = true,
        },
      })
    end,
  },
}
