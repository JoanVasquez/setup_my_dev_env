return {
	{
		"milanglacier/minuet-ai.nvim",
		event = "InsertEnter",
		cmd = "Minuet",
		dependencies = { "hrsh7th/nvim-cmp" },
		keys = { { "<leader>at", "<cmd>Minuet virtualtext toggle<cr>", desc = "AI: Toggle inline suggestions" } },

		config = function()
			require("minuet").setup({
				-- Ollama with Fill-in-the-Middle support
				provider = "openai_fim_compatible",
				enable_predicates = {
					function()
						local buffers = require("config.buffers")
						return buffers.can_edit() and not buffers.is_large() and not buffers.is_generated()
					end,
				},

				-- Performance tuning for local inference
				n_completions = 1,
				context_window = 1024,
				request_timeout = 10,
				throttle = 400,
				debounce = 250,

				-- Inline ghost-text suggestions
				virtualtext = {
					auto_trigger_ft = { "*" },

					-- Don't suggest in the filetypes
					auto_trigger_ignore_ft = {
						"TelescopePrompt",
						"markdown",
						"neo-tree",
						"help",
						"lazy",
						"mason",
					},

					-- Hide ghost text when the nvim-cmp menu visible
					show_on_completion_menu = false,

					keymap = {
						accept = "<C-l>",
						accept_line = "<C-g>",
						next = "<C-p>",
						prev = "<C-n>",
						dismiss = "<C-x>",
					},
				},

				-- Ollama provider
				provider_options = {
					openai_fim_compatible = {
						name = "Ollama",

						-- Ollama doesn't require authentication
						-- Use a fixed local placeholder instead of an environment variable
						api_key = function()
							return "ollama"
						end,

						end_point = "http://127.0.0.1:11434/v1/completions",

						model = "qwen2.5-coder:7b",

						optional = {
							max_tokens = 128,
							top_p = 0.9,
						},
					},
				},
			})

			-- InsertEnter can occur after FileType for the first opened buffer.
			local ft = vim.bo.filetype
			local ignored = require("minuet").config.virtualtext.auto_trigger_ignore_ft
			if ft ~= "" and vim.bo.buftype == "" and not vim.tbl_contains(ignored, ft) then
				vim.b.minuet_virtual_text_auto_trigger = true
			end
		end,
	},
}
