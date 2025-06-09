return {
  "folke/tokyonight.nvim",
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "night",
    })
    vim.cmd("colorscheme tokyonight")

    vim.api.nvim_set_hl(0, "Comment", { fg = "#9ca3af", italic = true }) -- customize as needed
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#a0a8c3", italic = true })
    vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#a0a8c3", italic = true })
  end,
}
