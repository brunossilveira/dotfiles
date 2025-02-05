return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  init = function()
    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "openai" },
        inline = { adapter = "openai" },
      },
      adapters = {
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            schema = {
              model = {
                default = "o3-mini-2025-01-31",
              },
            },
          })
        end,
      },
    })
  end,
  keys = {
    { "<leader>ac", "<cmd>CodeCompanionChat<CR>", desc = "Open CodeCompanion Chat" },
    { "<leader>ai", "<cmd>CodeCompanion<CR>", desc = "Open CodeCompanion Prompt" },
    { "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "Open CodeCompanion Actions" },
  },
}
