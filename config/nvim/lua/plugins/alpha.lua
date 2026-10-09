return {
	"goolord/alpha-nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local dashboard = require("alpha.themes.dashboard")
		dashboard.section.header.val = {
			"",
			"██████╗ ██╗   ██╗██████╗ ██╗   ██╗██████╗ ███████╗██╗   ██╗",
			"██╔══██╗██║   ██║██╔══██╗██║   ██║██╔══██╗██╔════╝██║   ██║",
			"██████╔╝██║   ██║██████╔╝██║   ██║██║  ██║█████╗  ██║   ██║",
			"██╔══██╗██║   ██║██╔══██╗██║   ██║██║  ██║██╔══╝  ╚██╗ ██╔╝",
			"██████╔╝╚██████╔╝██████╔╝╚██████╔╝██████╔╝███████╗ ╚████╔╝ ",
			"╚═════╝  ╚═════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝  ╚═══╝  ",
			"",
			"N E O V I M   /   A   Q U I E T   P L A C E   T O   B U I L D",
		}
		dashboard.section.header.opts.hl = "AlphaHeader"
		local icon = function(glyph)
			return vim.g.have_nerd_font and glyph or "•"
		end
		dashboard.section.buttons.val = {
			dashboard.button("f", icon("") .. "  Find a file", "<cmd>Telescope find_files<CR>"),
			dashboard.button("r", icon("") .. "  Recent files", "<cmd>Telescope oldfiles<CR>"),
			dashboard.button("g", icon("󰱼") .. "  Search project", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("n", icon("") .. "  New file", "<cmd>ene | startinsert<CR>"),
			dashboard.button("c", icon("") .. "  Configuration", "<cmd>edit " .. vim.fn.fnameescape(vim.fn.stdpath("config") .. "/init.lua") .. "<CR>"),
			dashboard.button("l", icon("󰒲") .. "  Plugins", "<cmd>Lazy<CR>"),
			dashboard.button("q", icon("󰅚") .. "  Quit", "<cmd>qa<CR>"),
		}
		for _, button in ipairs(dashboard.section.buttons.val) do
			button.opts.hl = "AlphaButtons"
			button.opts.hl_shortcut = "AlphaShortcut"
		end
		dashboard.section.footer.val = "Make something worth making."
		dashboard.section.footer.opts.hl = "AlphaFooter"
		dashboard.config.layout[1].val = 3
		require("alpha").setup(dashboard.config)
	end,
}
