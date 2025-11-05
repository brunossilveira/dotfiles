return {
  "williamboman/mason.nvim",
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_tool_installer = require("mason-tool-installer")

    mason.setup({
      ui = {
        icons = {
          package_installed = "􀆅",
          package_pending = "􀰑",
          package_uninstalled = "􀆄",
        },
      },
    })

    mason_tool_installer.setup({
      ensure_installed = {
        -- Formatters (fallback when Docker not available)
        "prettier",
        "stylua",
        "isort",
        "black",
        -- Linters (fallback when Docker not available)
        "pylint",
        "eslint_d",
        "tflint",
        -- LSP servers (host-based, not project-specific)
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "lua-language-server",
        "prisma-language-server",
        "pyright",
        "terraform-ls",
        "marksman",
      },
    })
  end,
}
