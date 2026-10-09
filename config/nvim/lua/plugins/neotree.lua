return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		keys = { { "<leader>e", "<cmd>Neotree toggle filesystem left<cr>", desc = "Explorer" } },

		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			"s1n7ax/nvim-window-picker",
		},

		opts = {
			-- Close the explorer when no editing windows remain
			close_if_last_window = true,
			popup_border_style = "rounded",

			window = {
				position = "left",
				width = 32,
				mappings = {
					["<bs>"] = "none",
				},
			},

			filesystem = {
				follow_current_file = {
					enabled = true,
				},

				hijack_netrw_behavior = "open_default",
			},

			default_component_configs = {
				indent = { indent_size = 2, padding = 1, with_markers = true, indent_marker = "│", last_indent_marker = "└", with_expanders = true },
				icon = {
					folder_closed = "",
					folder_open = "",
					folder_empty = "",
					folder_empty_open = "",
					default = "󰈙",
					highlight = "NeoTreeFileIcon",
				},

				git_status = {
					symbols = {
						added = "",
						modified = "󰏫",
						deleted = "",
						renamed = "󰁕",
						untracked = "",
						ignored = "",
						unstaged = "󰄱",
						staged = "",
						conflict = "",
					},
				},

				diagnostics = {
					symbols = {
						hint = "󰌶",
						info = "󰋽",
						warn = "󰀪",
						error = "󰅚",
					},
				},
			},
		},
	},

	{
		"antosha417/nvim-lsp-file-operations",
		lazy = true,

		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-neo-tree/neo-tree.nvim",
		},

		config = function()
			require("lsp-file-operations").setup()
		end,
	},

	{
		"s1n7ax/nvim-window-picker",
		version = "2.*",
		lazy = true,

		config = function()
			require("window-picker").setup({
				filter_rules = {
					include_current_win = false,
					autoselect_one = true,

					bo = {
						filetype = {
							"neo-tree",
							"neo-tree-popup",
							"notify",
						},

						buftype = {
							"terminal",
							"quickfix",
						},
					},
				},
			})
		end,
	},
}
