-- Shows available motions as virtual-text hints around the cursor (word
-- jumps, f/t targets, matching pairs, paragraph/file jumps) BEFORE you move
-- -- discovery instead of after-the-fact correction.
return {
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>uh", function() require("precognition").toggle() end, desc = "Toggle motion hints" },
    },
  },
}
