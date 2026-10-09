return {
	{ "b0o/SchemaStore.nvim", lazy = true },
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"b0o/SchemaStore.nvim",
			"antosha417/nvim-lsp-file-operations",
		},
		config = function()
			require("config.lsp").setup()
			vim.lsp.config("*", {
				capabilities = vim.tbl_deep_extend(
					"force",
					require("cmp_nvim_lsp").default_capabilities(),
					require("lsp-file-operations").default_capabilities()
				),
			})

			vim.lsp.config("basedpyright", {
				before_init = function(_, config)
					local python = require("config.python").interpreter(config.root_dir)
					if python then
						config.settings =
							vim.tbl_deep_extend("force", config.settings or {}, { python = { pythonPath = python } })
					end
				end,
				settings = {
					basedpyright = {
						analysis = {
							diagnosticSeverityOverrides = { reportUnusedImport = "none" },
							autoImportCompletions = true,
							autoSearchPaths = true,
							diagnosticMode = "openFilesOnly",
							typeCheckingMode = "standard",
						},
					},
				},
			})
			vim.lsp.config("bashls", {
				settings = {
					bashIde = { globPattern = "**/*@(.sh|.inc|.bash|.command)", includeAllWorkspaceSymbols = true },
				},
			})
			vim.lsp.config("lua_ls", {
				on_init = function(client)
					-- Only Neovim projects need Neovim globals and runtime definitions.
					if client.root_dir == vim.fn.stdpath("config") then
						client.settings.Lua = vim.tbl_deep_extend("force", client.settings.Lua or {}, {
							runtime = { version = "LuaJIT" },
							workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
							diagnostics = { globals = { "vim" } },
						})
						client:notify("workspace/didChangeConfiguration", { settings = client.settings })
					end
				end,
				settings = { Lua = { completion = { callSnippet = "Replace" }, format = { enable = false } } },
			})
			vim.lsp.config("ts_ls", {
				init_options = {
					preferences = {
						includeCompletionsForModuleExports = true,
						includePackageJsonAutoImports = "auto",
						includeCompletionsForImportStatements = true,
						importModuleSpecifierPreference = "shortest",
						quotePreference = "auto",
					},
				},
				settings = {
					typescript = { completions = { completeFunctionCalls = true } },
					javascript = { completions = { completeFunctionCalls = true } },
				},
			})
			vim.lsp.config("jsonls", {
				settings = { json = { validate = { enable = true }, schemas = require("schemastore").json.schemas() } },
			})
			vim.lsp.config("yamlls", {
				filetypes = { "yaml", "yaml.docker-compose" },
				settings = {
					yaml = {
						validate = true,
						hover = true,
						completion = true,
						schemaStore = { enable = false, url = "" },
						schemas = require("schemastore").yaml.schemas(),
					},
				},
			})
			vim.lsp.config("html", { filetypes = { "html", "htmldjango" } })
			vim.lsp.config("sqls", {
				root_markers = { "sqls.yml", ".sqls.yml", ".git" },
				cmd = function(dispatchers, config)
					local cmd = { "sqls" }
					if config.root_dir then
						for _, name in ipairs({ "sqls.yml", ".sqls.yml" }) do
							local path = vim.fs.joinpath(config.root_dir, name)
							if vim.uv.fs_stat(path) then
								vim.list_extend(cmd, { "-config", path })
								break
							end
						end
					end
					return vim.lsp.rpc.start(cmd, dispatchers, { cwd = config.root_dir })
				end,
			})
			vim.lsp.config("jdtls", {
				cmd = function(dispatchers, config)
					local root = config.root_dir or vim.fn.getcwd()
					local workspace = vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls", vim.fn.sha256(root))
					vim.fn.mkdir(workspace, "p")
					return vim.lsp.rpc.start({ "jdtls", "-data", workspace }, dispatchers, { cwd = root })
				end,
				settings = {
					java = {
						configuration = { updateBuildConfiguration = "interactive" },
						completion = {
							favoriteStaticMembers = { "org.junit.jupiter.api.Assertions.*", "org.mockito.Mockito.*" },
						},
					},
				},
			})
			vim.lsp.enable({
				"lua_ls",
				"ts_ls",
				"basedpyright",
				"ruff",
				"bashls",
				"jdtls",
				"sqls",
				"lemminx",
				"eslint",
				"html",
				"cssls",
				"tailwindcss",
				"emmet_language_server",
				"jsonls",
				"yamlls",
				"dockerls",
				"docker_compose_language_service",
			})
		end,
	},
}
