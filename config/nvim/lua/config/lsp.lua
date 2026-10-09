local M = {}

function M.setup()
	-- LSP Attach

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("user-lsp-configuration", {
			clear = true,
		}),

		callback = function(event)
			local client = vim.lsp.get_client_by_id(event.data.client_id)

			if not client then
				return
			end

			local bufnr = event.buf

			if client.name == "ruff" then
				client.server_capabilities.hoverProvider = false
			end

			local map = function(keys, func, desc, mode)
				vim.keymap.set(mode or "n", keys, func, {
					buffer = bufnr,
					desc = "LSP: " .. desc,
					silent = true,
				})
			end

			-- Navigation

			map("grr", "<cmd>Telescope lsp_references<cr>", "References")
			map("gri", "<cmd>Telescope lsp_implementations<cr>", "Implementation")
			map("grd", "<cmd>Telescope lsp_definitions<cr>", "Definition")
			map("grt", "<cmd>Telescope lsp_type_definitions<cr>", "Type Definition")

			map("grD", vim.lsp.buf.declaration, "Declaration")

			map("gO", "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols")
			map("gW", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace Symbols")

			-- Hover documentation
			map("K", vim.lsp.buf.hover, "Hover Documentation")

			-- Signature help
			map("<C-s>", vim.lsp.buf.signature_help, "Signature Help", "i")

			-- Rename

			if client:supports_method(vim.lsp.protocol.Methods.textDocument_rename, bufnr) then
				map("grn", vim.lsp.buf.rename, "Rename")
			end

			-- Code Actions

			if client:supports_method(vim.lsp.protocol.Methods.textDocument_codeAction, bufnr) then
				map("gra", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
			end

			-- Auto import / quick fixes
			map("<leader>ai", function()
				vim.lsp.buf.code_action({
					apply = true,

					context = {
						only = {
							"quickfix",
						},

						diagnostics = vim.diagnostic.get(bufnr),
					},
				})
			end, "Auto Import / Quick Fix")

			-- Diagnostics

			map("<leader>ld", function()
				vim.diagnostic.open_float({
					border = "rounded",
				})
			end, "Diagnostic Float")

			map("[d", function()
				vim.diagnostic.jump({
					count = -1,
					float = true,
				})
			end, "Previous Diagnostic")

			map("]d", function()
				vim.diagnostic.jump({
					count = 1,
					float = true,
				})
			end, "Next Diagnostic")

			map("<leader>q", vim.diagnostic.setloclist, "Diagnostics List")

			-- Inlay Hints

			if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, bufnr) then
				map("<leader>th", function()
					local enabled = vim.lsp.inlay_hint.is_enabled({
						bufnr = bufnr,
					})

					vim.lsp.inlay_hint.enable(not enabled, {
						bufnr = bufnr,
					})
				end, "Toggle Inlay Hints")
			end

			-- Document Highlight
			-- Highlight references to the symbol under the cursor

			if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, bufnr) then
				local highlight_group = vim.api.nvim_create_augroup("lsp-document-highlight-" .. bufnr, {
					clear = true,
				})

				vim.api.nvim_create_autocmd({
					"CursorHold",
					"CursorHoldI",
				}, {
					buffer = bufnr,
					group = highlight_group,
					callback = vim.lsp.buf.document_highlight,
				})

				vim.api.nvim_create_autocmd({
					"CursorMoved",
					"CursorMovedI",
				}, {
					buffer = bufnr,
					group = highlight_group,
					callback = vim.lsp.buf.clear_references,
				})

				vim.api.nvim_create_autocmd("LspDetach", {
					buffer = bufnr,
					group = vim.api.nvim_create_augroup("lsp-detach-" .. bufnr, {
						clear = true,
					}),

					callback = function(detach_event)
						-- Another attached server may still provide document highlights.
						for _, other in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
							if
								other.id ~= detach_event.data.client_id
								and other:supports_method("textDocument/documentHighlight", bufnr)
							then
								return
							end
						end
						vim.lsp.util.buf_clear_references(bufnr)
						vim.api.nvim_del_augroup_by_id(highlight_group)
						vim.api.nvim_del_augroup_by_name("lsp-detach-" .. bufnr)
					end,
				})
				vim.api.nvim_create_autocmd("BufWipeout", {
					buffer = bufnr,
					group = highlight_group,
					once = true,
					callback = function()
						vim.api.nvim_del_augroup_by_id(highlight_group)
						pcall(vim.api.nvim_del_augroup_by_name, "lsp-detach-" .. bufnr)
					end,
				})
			end
		end,
	})

	-- Diagnostics

	vim.diagnostic.config({
		severity_sort = true,

		update_in_insert = false,

		float = {
			border = "rounded",
			source = true,
			header = "",
			prefix = "",
		},

		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "󰅚 ",
				[vim.diagnostic.severity.WARN] = "󰀪 ",
				[vim.diagnostic.severity.INFO] = "󰋽 ",
				[vim.diagnostic.severity.HINT] = "󰌶 ",
			},
		},

		underline = true,

		virtual_text = {
			source = "if_many",
			spacing = 2,

			severity = {
				min = vim.diagnostic.severity.WARN,
			},
		},
	})
end

return M
