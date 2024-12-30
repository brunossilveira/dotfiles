return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons", "junegunn/fzf", build = "./install --bin" },
  config = function()
    require("fzf-lua").setup({})

    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<c-P>", require("fzf-lua").files, { desc = "Fzf Files" })
    keymap.set("n", "<leader>fs", "<cmd>FzfLua live_grep<cr>", { desc = "Find string in cwd" })
    keymap.set("n", "<leader>fc", "<cmd>FzfLua grep_cword<cr>", { desc = "Find string under cursor in cwd" })
  end,
}
