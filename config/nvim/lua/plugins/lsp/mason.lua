return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "􀆅",
          package_pending = "􀰑",
          package_uninstalled = "􀆄",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "ruby_lsp",
        --"tsserver",
        "html",
        "cssls",
        "tailwindcss",
        "lua_ls",
        "prismals",
        "pyright",
        "tflint",
        "marksman",
      },
      automatic_installation = false, -- disable automatic installation to avoid enable error
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "erb-formatter",
        "erb-lint",
        "rubocop",
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "isort", -- python formatter
        "black", -- python formatter
        "pylint",
        "eslint_d",
        "tflint",
        "marksman",
      },
    })
  end,
}
