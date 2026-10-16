return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern",
		delay = 400,
		win = { border = "rounded" },
		spec = {
			{ "<leader>c", group = "Code" },
			{ "<leader>f", group = "Find" },
			{ "<leader>g", group = "Git" },
			{ "<leader>gh", group = "Git hunks" },
			{ "<leader>p", group = "Project sessions" },
			{ "<leader>r", group = "Run tasks" },
			{ "<leader>l", group = "Language tools" },
			{ "<leader>s", group = "Search / save" },
			{ "<leader>t", group = "Toggles" },
			{ "<leader>w", group = "Windows" },
		},
	},
}
