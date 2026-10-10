return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",

		config = function()
			local treesitter = require("nvim-treesitter")
			vim.treesitter.language.register("json", "jsonc")
			vim.treesitter.language.register("yaml", "yaml.docker-compose")
			vim.treesitter.language.register("html", "htmldjango")

			-- Parsers to install
			local parsers = {
				-- Neovim
				"lua",
				"vim",
				"vimdoc",
				"query",

				-- JavaScript / TypeScript
				"javascript",
				"typescript",
				"tsx",

				-- Python
				"python",

				-- Java
				"java",

				-- Shell
				"bash",

				-- Web
				"html",
				"css",
				"scss",

				-- Config / Data
				"json",
				"yaml",
				"toml",
				"sql",
				"xml",
				"csv",
				"jinja",
				"jinja_inline",

				-- Docker
				"dockerfile",

				-- Documentation
				"markdown",
				"markdown_inline",
			}

			-- Keep normal startup offline; install the configured set explicitly.
			vim.api.nvim_create_user_command("TreesitterInstall", function(args)
				local installation = treesitter.install(parsers, { summary = true, max_jobs = 4 })
				if args.bang then
					installation:wait(300000)
					local installed = treesitter.get_installed("parsers")
					for _, parser in ipairs(parsers) do
						assert(vim.tbl_contains(installed, parser), "Parser installation failed: " .. parser)
					end
				end
			end, { bang = true, desc = "Install configured Treesitter parsers (! waits and verifies)" })

			-- Enable Treesitter highlighting automatically
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("development-treesitter", { clear = true }),
				callback = function(event)
					local buffers = require("config.buffers")
					if buffers.can_edit(event.buf) and not buffers.is_large(event.buf) then
						pcall(vim.treesitter.start, event.buf)
					end
				end,
			})
		end,
	},
}
