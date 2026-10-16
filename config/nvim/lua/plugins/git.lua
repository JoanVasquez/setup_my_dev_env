return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			current_line_blame = false,
			on_attach = function(buf)
				local gs = require("gitsigns")
				local function map(lhs, rhs, desc, mode)
					vim.keymap.set(mode or "n", lhs, rhs, { buffer = buf, desc = desc, silent = true })
				end
				map("]h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gs.nav_hunk("next")
					end
				end, "Next Git hunk")
				map("[h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gs.nav_hunk("prev")
					end
				end, "Previous Git hunk")
				map("<leader>ghs", gs.stage_hunk, "Stage / unstage hunk")
				map("<leader>ghs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage selected lines", "x")
				map("<leader>ghp", gs.preview_hunk, "Preview hunk")
				map("<leader>ghb", gs.blame_line, "Blame line")
				map("<leader>ghd", gs.diffthis, "Diff current file")
				map("<leader>tb", gs.toggle_current_line_blame, "Toggle Git blame")
				map("ih", gs.select_hunk, "Select Git hunk", { "o", "x" })
			end,
		},
	},
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
		opts = {},
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Review project diff" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff review" },
		},
	},
}
