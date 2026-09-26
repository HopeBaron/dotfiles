-- Buffer-local keymaps, applied whenever ANY LSP server attaches --
-- language-agnostic, works the same no matter which server(s) you install
-- later via :Mason.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
    end

    map("n", "K", vim.lsp.buf.hover, "Hover docs")
    map("n", "gd", function() require("telescope.builtin").lsp_definitions() end, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gr", function() require("telescope.builtin").lsp_references() end, "References")
    map("n", "gI", function() require("telescope.builtin").lsp_implementations() end, "Implementations")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
  end,
})
