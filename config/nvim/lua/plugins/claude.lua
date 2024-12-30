return {
  "pasky/claude.vim",
  lazy = false,
  config = function()
    -- Load API key from environment variable
    local api_key = "key"

    if api_key then
      vim.g.claude_api_key = api_key
    else
      vim.notify("ANTHROPIC_API_KEY environment variable is not set", vim.log.levels.WARN)
    end

    -- Add keymaps
    vim.keymap.set("v", "<leader>ci", ":'<,'>ClaudeImplement ", { noremap = true, desc = "Claude Implement" })
    vim.keymap.set("n", "<leader>cc", ":ClaudeChat<CR>", { noremap = true, silent = true, desc = "Claude Chat" })
  end,
}
