return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",

		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},

		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Load VS Code-compatible snippets
			luasnip.config.setup({ region_check_events = "CursorMoved", delete_check_events = "TextChanged" })
			luasnip.filetype_extend("htmldjango", { "html", "django" })
			luasnip.filetype_extend("yaml.docker-compose", { "yaml" })
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				enabled = function()
					return require("config.buffers").can_edit() and not require("config.buffers").is_large()
				end,
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},

				-- ==========================================
				-- Completion formatting
				-- ==========================================
				formatting = {
					fields = { "kind", "abbr", "menu" },

					format = function(entry, vim_item)
						local source_names = {
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
						}

						vim_item.menu = source_names[entry.source.name] or ""

						return vim_item
					end,
				},

				mapping = cmp.mapping.preset.insert({
					-- Manually trigger completion
					["<C-Space>"] = cmp.mapping.complete(),

					-- Navigate completion menu
					["<C-j>"] = cmp.mapping.select_next_item(),
					["<C-k>"] = cmp.mapping.select_prev_item(),

					-- Close completion menu
					["<C-e>"] = cmp.mapping.abort(),

					-- Accept selected completion
					["<CR>"] = cmp.mapping.confirm({
						select = false,
					}),

					-- Smart Tab
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),

					-- Shift+Tab
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),

				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),

				-- Minuet handles our AI ghost text
				experimental = {
					ghost_text = false,
				},

				completion = {
					completeopt = "menu,menuone,noselect",
					autocomplete = { cmp.TriggerEvent.TextChanged },
				},
			})
		end,
	},
}
