vim.filetype.add({
	pattern = {
		["compose%.ya?ml"] = "yaml.docker-compose",
		["compose%..*%.ya?ml"] = "yaml.docker-compose",
		["docker%-compose%.ya?ml"] = "yaml.docker-compose",
		["docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",
		[".*/templates/.*%.html"] = "htmldjango",
		["Dockerfile%..*"] = "dockerfile",
	},
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("development-indentation", { clear = true }),
	pattern = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"html",
		"htmldjango",
		"css",
		"scss",
		"json",
		"jsonc",
		"yaml",
		"yaml.docker-compose",
	},
	callback = function()
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.tabstop = 2
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = "development-indentation",
	pattern = "lua",
	callback = function()
		-- Match this config's StyLua defaults; EditorConfig can override these.
		vim.opt_local.expandtab = false
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
		vim.opt_local.softtabstop = 4
	end,
})
