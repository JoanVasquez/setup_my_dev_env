return {
	{
		"mason-org/mason.nvim",
		lazy = false,
		priority = 1000,

		opts = {
			ui = {
				border = "rounded",

				icons = {
					package_pending = " ",
					package_installed = " ",
					package_uninstalled = " ",
				},
			},
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		dependencies = {
			"mason-org/mason.nvim",
		},

		opts = {
			ensure_installed = {
				-- LSP
				"lua-language-server",
				"typescript-language-server",
				"basedpyright",
				"jdtls",
				"sqls",
				"lemminx",
				"bash-language-server",

				"eslint-lsp",
				"html-lsp",
				"css-lsp",
				"tailwindcss-language-server",
				"emmet-language-server",

				"json-lsp",
				"yaml-language-server",

				"dockerfile-language-server",
				"docker-compose-language-service",

				-- Formatters
				"stylua",
				"djlint",
				"sqlfluff",
				"prettierd",
				"shfmt",

				-- Linters
				"ruff",
				"shellcheck",
				"hadolint",
			},

			auto_update = false,
			run_on_start = false,
		},
	},
}
