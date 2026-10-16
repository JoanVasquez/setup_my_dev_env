return {
	{
		"nvim-mini/mini.nvim",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()
			require("mini.pairs").setup()
			require("mini.splitjoin").setup()
			require("mini.align").setup()
		end,
	},
	{
		"folke/flash.nvim",
		opts = { modes = { char = { enabled = false }, search = { enabled = false } } },
		keys = {
			{
				"s",
				function()
					require("flash").jump()
				end,
				mode = { "n", "x", "o" },
				desc = "Jump with labels",
			},
			{
				"S",
				function()
					require("flash").treesitter()
				end,
				mode = { "n", "x", "o" },
				desc = "Select syntax node",
			},
		},
	},
	{
		"MagicDuck/grug-far.nvim",
		cmd = "GrugFar",
		opts = {},
		keys = {
			{
				"<leader>sr",
				function()
					require("grug-far").open()
				end,
				desc = "Project search and replace",
			},
			{
				"<leader>sw",
				function()
					require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
				end,
				desc = "Replace word in project",
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
		keys = {
			{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next TODO",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous TODO",
			},
		},
	},
}
