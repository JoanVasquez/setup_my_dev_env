return {
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
		keys = {
			{ "<leader>ll", "<cmd>Trouble diagnostics toggle<cr>", desc = "Project diagnostics" },
			{ "<leader>lb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
			{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbol outline" },
			{ "<leader>lq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix panel" },
		},
	},
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {},
		keys = {
			{
				"<leader>pr",
				function()
					require("persistence").load()
				end,
				desc = "Restore project session",
			},
			{
				"<leader>pl",
				function()
					require("persistence").load({ last = true })
				end,
				desc = "Restore last session",
			},
			{
				"<leader>ps",
				function()
					require("persistence").select()
				end,
				desc = "Select session",
			},
			{
				"<leader>pd",
				function()
					require("persistence").stop()
				end,
				desc = "Stop session recording",
			},
		},
	},
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd = { "ToggleTerm", "TermExec" },
		opts = {
			open_mapping = [[<c-\>]],
			direction = "float",
			float_opts = { border = "rounded" },
			persist_mode = false,
		},
		keys = {
			{ [[<C-\>]], "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
			{ "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Floating terminal" },
		},
	},
	{
		"stevearc/overseer.nvim",
		cmd = { "OverseerRun", "OverseerToggle", "OverseerQuickAction", "OverseerTaskAction" },
		opts = {},
		keys = {
			{ "<leader>rr", "<cmd>OverseerRun<cr>", desc = "Run project task" },
			{ "<leader>rt", "<cmd>OverseerToggle<cr>", desc = "Task output panel" },
			{ "<leader>ra", "<cmd>OverseerTaskAction<cr>", desc = "Task actions" },
		},
	},
}
