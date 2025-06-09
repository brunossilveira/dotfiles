return {
  "MagicDuck/grug-far.nvim",
  opts = { open_cmd = "noswapfile vnew" },
  keys = {
    {
      "<leader>sr",
      function()
        require("grug-far").open()
      end,
      desc = "Replace in files (Grug)",
    },
  },
}
