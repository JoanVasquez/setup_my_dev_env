return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		style = "moon",
		-- Let the terminal control background opacity and desktop blur.
		transparent = true,
		styles = {
			comments = { italic = true },
			keywords = { italic = true },
			sidebars = "transparent",
			floats = "transparent",
		},
		sidebars = { "neo-tree", "help", "qf", "terminal", "alpha" },
		on_highlights = function(hl, c)
			hl.AlphaHeader = { fg = c.purple, bold = true }
			hl.AlphaButtons = { fg = c.fg }
			hl.AlphaShortcut = { fg = c.blue }
			hl.AlphaFooter = { fg = c.comment, italic = true }
			hl.FloatBorder = { fg = c.blue, bg = c.bg_float }
			hl.WinSeparator = { fg = c.bg_highlight, bg = c.none }
			hl.CursorLineNr = { fg = c.orange, bold = true }
			hl.TelescopeBorder = { fg = c.blue, bg = c.bg_float }
			hl.TelescopeNormal = { fg = c.fg, bg = c.bg_float }
			hl.TelescopePromptBorder = { fg = c.blue, bg = c.none }
			hl.TelescopePromptNormal = { fg = c.fg, bg = c.none }
			hl.TelescopePromptTitle = { fg = c.bg, bg = c.purple, bold = true }
			hl.TelescopePreviewTitle = { fg = c.bg, bg = c.green, bold = true }
			hl.TelescopeResultsTitle = { fg = c.bg, bg = c.blue, bold = true }
		end,
	},
	config = function(_, opts)
		require("tokyonight").setup(opts)
		vim.cmd.colorscheme("tokyonight-moon")
	end,
}
