return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = function()
		local p = require("config.palette")
		local function mode(accent)
			return {
				a = { fg = p.bg, bg = accent, gui = "bold" },
				b = { fg = accent, bg = p.panel },
				c = { fg = p.fg, bg = p.bg },
			}
		end
		return {
			options = {
				theme = {
					normal = mode(p.blue),
					insert = mode(p.green),
					visual = mode(p.violet),
					replace = mode(p.coral),
					command = mode(p.amber),
					inactive = mode(p.muted),
				},
				globalstatus = true,
				section_separators = { left = "", right = "" },
				component_separators = { left = "", right = "" },
				disabled_filetypes = { statusline = { "lazy", "alpha" } },
			},
			sections = {
				lualine_a = { {
					"mode",
					fmt = function(mode)
						return " " .. mode
					end,
				} },
				lualine_b = { { "branch", icon = "" }, "diff" },
				lualine_c = { { "filename", path = 1 }, "diagnostics" },
				lualine_x = {
					{
						function()
							local names = {}
							for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
								names[#names + 1] = client.name
							end
							table.sort(names)
							return table.concat(names, ", ")
						end,
						icon = "",
						color = { fg = p.green },
						cond = function()
							return vim.o.columns > 120
						end,
					},
					{
						"filetype",
						cond = function()
							return vim.o.columns > 90
						end,
					},
				},
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			extensions = { "neo-tree", "quickfix", "lazy", "mason" },
		}
	end,
}
