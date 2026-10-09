local function picker(name, opts)
	return function()
		require("telescope.builtin")[name](opts)
	end
end

local function git_picker(name)
	return function()
		local result = vim.system({ "git", "rev-parse", "--is-inside-work-tree" }, { text = true }):wait()
		if result.code ~= 0 then
			vim.notify("Not inside a Git repository", vim.log.levels.WARN, { title = "Telescope" })
			return
		end
		require("telescope.builtin")[name]()
	end
end

return {
	"nvim-telescope/telescope.nvim",
	version = "*",
	cmd = "Telescope",
	event = "VeryLazy",
	keys = {
		{ "<leader>ff", picker("find_files"), desc = "Find files" },
		{ "<leader>fg", picker("live_grep"), desc = "Search project text" },
		{ "<leader>fb", picker("buffers"), desc = "Buffers" },
		{ "<leader>fh", picker("help_tags"), desc = "Help tags" },
		{ "<leader>fk", picker("keymaps"), desc = "Keymaps" },
		{ "<leader>fr", picker("oldfiles"), desc = "Recent files" },
		{ "<leader>gc", git_picker("git_commits"), desc = "Git commits" },
		{ "<leader>gb", git_picker("git_branches"), desc = "Git branches" },
		{ "<leader>gs", git_picker("git_status"), desc = "Git status" },
		{
			"<leader>/",
			function()
				require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 0,
					previewer = false,
				}))
			end,
			desc = "Search current buffer",
		},
		{
			"<leader>s/",
			picker("live_grep", { grep_open_files = true, prompt_title = "Search Open Files" }),
			desc = "Search open files",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"nvim-telescope/telescope-ui-select.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		telescope.setup({
			defaults = {
				winblend = 0,
				border = true,
				prompt_prefix = "   ",
				selection_caret = "▎ ",
				sorting_strategy = "ascending",
				layout_config = {
					prompt_position = "top",
					width = 0.85,
					height = 0.75,
					horizontal = { preview_width = 0.55 },
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-l>"] = actions.select_default,
					},
				},
				file_ignore_patterns = {
					"^node_modules/",
					"/node_modules/",
					"^%.git/",
					"/%.git/",
					"^%.venv/",
					"/%.venv/",
					"^venv/",
					"/venv/",
					"^dist/",
					"/dist/",
					"^build/",
					"/build/",
				},
			},
			pickers = {
				find_files = { hidden = true },
				live_grep = {
					additional_args = function()
						return { "--hidden" }
					end,
				},
			},
			extensions = { ["ui-select"] = require("telescope.themes").get_dropdown() },
		})
		pcall(telescope.load_extension, "fzf")
		telescope.load_extension("ui-select")
	end,
}
