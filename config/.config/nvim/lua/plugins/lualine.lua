return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require("lualine").setup({
        options = {
          -- "auto" reads the active colorscheme, so switching variants via
          -- Themery (lua/plugins/themery.lua) re-themes this too, without
          -- hardcoding "gruvbox-material" here and needing to keep them in sync.
          theme = "auto",
          globalstatus = true,
        },
      })
    end,
  },
}
