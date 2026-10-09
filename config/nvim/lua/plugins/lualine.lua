return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = "tokyonight",
			globalstatus = true,
			section_separators = { left = "", right = "" },
			component_separators = { left = "", right = "" },
			disabled_filetypes = { statusline = { "lazy", "alpha" } },
		},
		sections = {
			lualine_a = { { "mode", fmt = function(mode)
				return " " .. mode
			end } },
			lualine_b = { { "branch", icon = "" }, "diff" },
			lualine_c = { { "filename", path = 1 }, "diagnostics" },
			lualine_x = { {
				"filetype",
				cond = function()
					return vim.o.columns > 90
				end,
			} },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		extensions = { "neo-tree", "quickfix", "lazy", "mason" },
	},
}
