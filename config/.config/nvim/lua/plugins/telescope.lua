return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end,   desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end,     desc = "Open buffers" },
      { "<leader>fo", function() require("telescope.builtin").oldfiles() end,    desc = "Recently opened files" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end,   desc = "Help tags" },
    },
    config = function()
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
}
