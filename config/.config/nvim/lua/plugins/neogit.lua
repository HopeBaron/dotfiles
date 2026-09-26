-- Full git porcelain UI (stage, commit, branch, push/pull, log, diff) as
-- Neovim buffers -- Magit-style, not a wrapped external terminal tool.
return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff: repo status" },
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "esmuellert/codediff.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", function() require("neogit").open() end, desc = "Neogit status" },
    },
    opts = {
      integrations = { codediff = true },
      diff_viewer = "codediff",
    },
  },
}
