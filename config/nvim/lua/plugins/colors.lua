return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		style = "moon",
		cache = false,
		-- Let the terminal control background opacity and desktop blur.
		transparent = true,
		styles = {
			comments = { italic = true },
			keywords = { italic = true },
			sidebars = "transparent",
			floats = "transparent",
		},
		sidebars = { "neo-tree", "help", "qf", "terminal", "alpha" },
		on_colors = function(c)
			local p = require("config.palette")
			c.bg = p.bg
			c.bg_dark = p.bg
			c.bg_float = p.panel
			c.bg_popup = p.panel
			c.bg_sidebar = p.panel
			c.bg_highlight = p.selection
			c.fg = p.fg
			c.fg_dark = p.muted
			c.comment = p.muted
			c.blue = p.blue
			c.cyan = p.cyan
			c.teal = p.cyan
			c.green = p.green
			c.green1 = p.green
			c.green2 = p.cyan
			c.purple = p.violet
			c.magenta = p.rose
			c.magenta2 = p.violet
			c.yellow = p.amber
			c.orange = p.coral
			c.red = p.red
		end,
		on_highlights = function(hl, c)
			hl.AlphaHeader = { fg = c.blue, bold = true }
			hl.AlphaButtons = { fg = c.fg }
			hl.AlphaShortcut = { fg = c.green, bold = true }
			hl.AlphaFooter = { fg = c.comment, italic = true }
			hl.FloatBorder = { fg = c.blue, bg = c.bg_float }
			hl.WinSeparator = { fg = c.bg_highlight, bg = c.none }
			hl.CursorLineNr = { fg = c.green, bold = true }
			hl.NeoTreeNormal = { fg = c.fg, bg = c.none }
			hl.NeoTreeNormalNC = { fg = c.fg, bg = c.none }
			hl.NeoTreeEndOfBuffer = { fg = c.bg_highlight, bg = c.none }
			hl.NeoTreeDirectoryIcon = { fg = c.blue }
			hl.NeoTreeDirectoryName = { fg = c.blue }
			hl.NeoTreeRootName = { fg = c.green, bold = true }
			hl.IblIndent = { fg = c.bg_highlight }
			hl.IblScope = { fg = c.green }
			hl.BufferLineIndicatorSelected = { fg = c.green }
			hl.BufferLineBufferSelected = { fg = c.blue, bold = true }
			hl.BufferLineModifiedSelected = { fg = c.yellow }
			hl.Keyword = { fg = c.purple, italic = true }
			hl["@keyword"] = { fg = c.purple, italic = true }
			hl["@keyword.function"] = { fg = c.purple, italic = true }
			hl["@keyword.return"] = { fg = c.magenta, italic = true }
			hl.TelescopeSelection = { fg = c.green, bg = c.bg_highlight, bold = true }
			hl.TelescopeMatching = { fg = c.yellow, bold = true }
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
