return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "markdown.mdx" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			heading = { sign = false },
			code = { border = "thin" },
		},
		keys = {
			{ "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown preview" },
		},
	},
}
