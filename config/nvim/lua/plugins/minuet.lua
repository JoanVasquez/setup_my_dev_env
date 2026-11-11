return {
	{
		"milanglacier/minuet-ai.nvim",
		event = "InsertEnter",
		cmd = "Minuet",
		dependencies = { "hrsh7th/nvim-cmp" },
		keys = { { "<leader>at", "<cmd>Minuet virtualtext toggle<cr>", desc = "AI: Toggle inline suggestions" } },

		config = function()
			local function accept_without_duplicate_closers(accept)
				local bufnr = vim.api.nvim_get_current_buf()
				local row, col = unpack(vim.api.nvim_win_get_cursor(0))
				local original_tail = vim.api.nvim_get_current_line():sub(col + 1)

				accept()
				vim.schedule(function()
					if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
						return
					end

					local new_row, new_col = unpack(vim.api.nvim_win_get_cursor(0))
					local line = vim.api.nvim_get_current_line()
					local tail = line:sub(new_col + 1)
					local closers = original_tail:match([[^[%]%)}>'"]+]])
					if new_row < row or not closers or tail:sub(1, #closers) ~= closers then
						return
					end

					-- If the model supplied the exact closers already waiting after the
					-- cursor (from mini.pairs), keep only the model's copy.
					local before = line:sub(1, new_col)
					for length = #closers, 1, -1 do
						local candidate = closers:sub(1, length)
						if before:sub(-length) == candidate and tail:sub(1, length) == candidate then
							vim.api.nvim_buf_set_text(0, new_row - 1, new_col, new_row - 1, new_col + length, {})
							break
						end
					end
				end)
			end

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
				-- Allow the first request to load the local model into GPU memory.
				request_timeout = 30,
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
						accept = nil,
						accept_line = nil,
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

			vim.keymap.set("i", "<C-l>", function()
				accept_without_duplicate_closers(require("minuet.virtualtext").action.accept)
			end, { desc = "Accept AI suggestion" })
			vim.keymap.set("i", "<C-g>", function()
				accept_without_duplicate_closers(require("minuet.virtualtext").action.accept_line)
			end, { desc = "Accept AI suggestion line" })

			-- InsertEnter can occur after FileType for the first opened buffer.
			local ft = vim.bo.filetype
			local ignored = require("minuet").config.virtualtext.auto_trigger_ignore_ft
			if ft ~= "" and vim.bo.buftype == "" and not vim.tbl_contains(ignored, ft) then
				vim.b.minuet_virtual_text_auto_trigger = true
			end
		end,
	},
}
