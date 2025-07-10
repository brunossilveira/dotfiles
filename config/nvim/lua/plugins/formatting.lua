return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        ruby = { "rubocop", "ruby-lsp" },
      },
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 3000, -- Increased timeout for rubocop
      },
      formatters = {
        prettier = {
          command = vim.fn.getcwd() .. "/app/javascript/node_modules/.bin/prettier",
        },
        ruby_lsp = {
          "~/.rbenv/shims/ruby-lsp",
        },
        rubocop = {
          command = function()
            -- Check if project has bin/rubocop, otherwise fall back to rbenv/system
            local project_rubocop = vim.fn.getcwd() .. "/bin/rubocop"
            if vim.fn.executable(project_rubocop) == 1 then
              return project_rubocop
            else
              return "rubocop" -- Let PATH resolution handle this
            end
          end,
          args = {
            "--no-server", -- Disable server mode to avoid mason conflicts
            "-a",
            "-f", 
            "quiet",
            "--stderr",
            "--stdin",
            "$FILENAME",
          },
          timeout = 5000, -- 5 second timeout for rubocop
        },
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 3000, -- Increased timeout for rubocop
      })
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
