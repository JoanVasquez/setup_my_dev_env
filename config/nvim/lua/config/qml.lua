local M = {}

-- Qt tools may use versioned names or live outside PATH on Linux.
function M.tool(name)
	for _, candidate in ipairs({ name, name .. "6", "/usr/lib/qt6/bin/" .. name, "/usr/lib64/qt6/bin/" .. name }) do
		if vim.fn.executable(candidate) == 1 then
			return candidate
		end
	end
	return name
end

return M
