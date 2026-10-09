return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			-- Bash LSP runs ShellCheck; ESLint and Ruff also run through LSP.
			lint.linters_by_ft = { dockerfile = { "hadolint" } }
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("development-lint", { clear = true }),
				callback = function()
					local buffers = require("config.buffers")
					if
						vim.bo.filetype == "dockerfile"
						and buffers.can_edit()
						and not buffers.is_generated()
						and not buffers.is_large()
						and vim.fn.executable("hadolint") == 1
					then
						lint.try_lint()
					end
				end,
			})
		end,
	},
}
