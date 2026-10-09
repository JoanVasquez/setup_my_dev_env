local function sql_root(_, ctx)
	local ini_files = { ["pep8.ini"] = true, ["setup.cfg"] = true, ["tox.ini"] = true }
	local config = vim.fs.find(function(name, directory)
		if name == ".sqlfluff" then
			return true
		end
		if name ~= "pyproject.toml" and not ini_files[name] then
			return false
		end
		local file = io.open(vim.fs.joinpath(directory, name), "r")
		if not file then
			return false
		end
		local content = file:read("*a")
		file:close()
		local section = name == "pyproject.toml" and "%[tool%.sqlfluff[%.%]]" or "%[sqlfluff[:%]]"
		return content:find(section) ~= nil
	end, { path = ctx.dirname, upward = true, type = "file", limit = 1 })[1]
	return config and vim.fs.dirname(config)
end

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo", "FormatDisable", "FormatEnable" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "x" },
			desc = "Format buffer or selection",
		},
	},
	opts = function()
		local prettier = { "prettierd", "prettier", stop_after_first = true }
		local formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_organize_imports", "ruff_format" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			htmldjango = { "djlint" },
			sql = { "sqlfluff" },
		}
		for _, ft in ipairs({
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"html",
			"css",
			"scss",
			"json",
			"jsonc",
			"yaml",
			"yaml.docker-compose",
			"markdown",
		}) do
			formatters_by_ft[ft] = vim.deepcopy(prettier)
		end
		return {
			formatters_by_ft = formatters_by_ft,
			formatters = {
				djlint = { prepend_args = { "--profile", "django" } },
				sqlfluff = { cwd = sql_root, require_cwd = true },
			},
			default_format_opts = { lsp_format = "fallback" },
			format_on_save = function(bufnr)
				local buffers = require("config.buffers")
				if
					vim.g.disable_autoformat
					or vim.b[bufnr].disable_autoformat
					or not buffers.can_edit(bufnr)
					or buffers.is_generated(bufnr)
					or buffers.is_large(bufnr)
				then
					return
				end
				return { timeout_ms = 1000, lsp_format = "fallback" }
			end,
			notify_on_error = true,
			notify_no_formatters = false,
		}
	end,
	config = function(_, opts)
		require("conform").setup(opts)
		vim.api.nvim_create_user_command("FormatDisable", function(args)
			if args.bang then
				vim.b.disable_autoformat = true
			else
				vim.g.disable_autoformat = true
			end
		end, { desc = "Disable format on save (! for current buffer)", bang = true })
		vim.api.nvim_create_user_command("FormatEnable", function(args)
			if args.bang then
				vim.b.disable_autoformat = false
			else
				vim.g.disable_autoformat = false
				vim.b.disable_autoformat = false
			end
		end, { desc = "Enable format on save (! for current buffer)", bang = true })
	end,
}
