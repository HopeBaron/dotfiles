-- LSP infra only -- no servers pre-installed. Run :Mason to browse and
-- install a server on demand; mason-lspconfig auto-enables (vim.lsp.enable)
-- anything installed that way, so nothing else needs editing afterwards.
-- LSP keymaps live in lua/config/lsp-keymaps.lua, required from init.lua --
-- they're a plain autocmd, not something that needs to be its own plugin.
return {
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    opts = {},
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
}
