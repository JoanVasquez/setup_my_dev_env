-- Run by dotfiles setup after the Neovim configuration is linked.
-- Check installed artifacts after synchronous installs: upstream download
-- failures must make setup fail instead of reporting an unusable editor ready.
local ok, err = pcall(function()
	assert(vim.v.errmsg == "", vim.v.errmsg)
	require("lazy").install({ wait = true, show = false })
	vim.cmd("MasonToolsInstallSync")
	local plugin = require("lazy.core.config").plugins["mason-tool-installer.nvim"]
	assert(plugin, "mason-tool-installer.nvim is unavailable")
	local opts = require("lazy.core.plugin").values(plugin, "opts", false)
	local registry = require("mason-registry")
	for _, tool in ipairs(opts.ensure_installed) do
		local name = type(tool) == "table" and tool[1] or tool
		assert(registry.get_package(name):is_installed(), "Language tool installation failed: " .. name)
	end
	vim.cmd("TreesitterInstall!")
	assert(vim.v.errmsg == "", vim.v.errmsg)
end)
if not ok then
	io.stderr:write("Neovim provisioning failed: " .. tostring(err) .. "\n")
	vim.cmd("cquit 1")
end
vim.cmd("qa!")
