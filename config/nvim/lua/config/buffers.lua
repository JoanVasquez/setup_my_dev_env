local M = {}

function M.is_large(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_line_count(bufnr)
	return lines > 20000 or vim.api.nvim_buf_get_offset(bufnr, lines) > 1024 * 1024
end

function M.is_generated(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr or 0):gsub("\\", "/")
	for _, directory in ipairs({ "node_modules", "vendor", ".venv", "venv", ".git" }) do
		if name:find("/" .. directory .. "/", 1, true) then
			return true
		end
	end
	return false
end

function M.can_edit(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].modifiable
end

-- Disable only Conform for this write; keep LSP, lint, and other save hooks.
function M.save_without_formatting()
	local bufnr = vim.api.nvim_get_current_buf()
	local previous = vim.b[bufnr].disable_autoformat
	vim.b[bufnr].disable_autoformat = true
	local ok, err = pcall(vim.cmd.write)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.b[bufnr].disable_autoformat = previous
	end
	if not ok then
		vim.notify(err, vim.log.levels.ERROR)
	end
end

return M
