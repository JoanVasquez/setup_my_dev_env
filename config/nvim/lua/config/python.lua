local M = {}

function M.interpreter(root)
	if vim.g.python_interpreter then
		return vim.g.python_interpreter
	end
	for _, env in ipairs({ vim.env.VIRTUAL_ENV or "", vim.env.CONDA_PREFIX or "" }) do
		if env ~= "" and vim.fn.executable(env .. "/bin/python") == 1 then
			return env .. "/bin/python"
		end
	end
	if root then
		for _, env in ipairs({ ".venv", "venv" }) do
			local python = root .. "/" .. env .. "/bin/python"
			if vim.fn.executable(python) == 1 then
				return python
			end
		end
	end
end

function M.setup()
	vim.api.nvim_create_user_command("PythonInterpreter", function(args)
		local path = vim.fn.fnamemodify(vim.fn.expand(args.args), ":p")
		if vim.fn.executable(path) ~= 1 then
			vim.notify("Python executable not found: " .. path, vim.log.levels.ERROR)
			return
		end
		vim.g.python_interpreter = path
		for _, client in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
			client.settings = vim.tbl_deep_extend("force", client.settings or {}, { python = { pythonPath = path } })
			client.config.settings = client.settings
			client:notify("workspace/didChangeConfiguration", { settings = client.settings })
		end
		vim.notify("Python interpreter: " .. path)
	end, { nargs = 1, complete = "file", desc = "Select Python interpreter for this Neovim session" })
end

return M
