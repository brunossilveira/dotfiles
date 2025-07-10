return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      ruby = { "rubocop" },
      javascript = { "eslint" },
      typescript = { "eslint" },
      javascriptreact = { "eslint" },
      typescriptreact = { "eslint" },
      python = { "pylint" },
    }

    -- Configure eslint to use project version
    local eslint = require("lint.linters.eslint")
    eslint.cmd = vim.fn.getcwd() .. "/app/javascript/node_modules/.bin/eslint"
    eslint.cwd = vim.fn.getcwd() .. "/app/javascript"
    
    -- Configure rubocop to prefer project version and disable server mode
    local rubocop = require("lint.linters.rubocop")
    rubocop.cmd = function()
      local project_rubocop = vim.fn.getcwd() .. "/bin/rubocop"
      if vim.fn.executable(project_rubocop) == 1 then
        return project_rubocop
      else
        return "rubocop"
      end
    end
    rubocop.args = vim.list_extend({ "--no-server" }, rubocop.args or {})

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
