return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false, -- this plugin does not support lazy-loading (upstream note)
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      -- No hardcoded language list: whenever a parser is installed (via
      -- :TSInstall <lang>, on demand), highlighting turns on for it the next
      -- time a file of that type is opened. Files with no installed parser
      -- just silently keep regular syntax highlighting (pcall swallows it).
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
