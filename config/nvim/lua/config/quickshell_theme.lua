local M = {}

function M.setup()
	if M.timer then
		return
	end
	local uv = vim.uv or vim.loop
	local state_home = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
	local state_file = state_home .. "/quickshell/palette"
	local function read_palette()
		local file = io.open(state_file, "r")
		if not file then
			return "Crimson"
		end
		local value = file:read("*l") or "Crimson"
		file:close()
		return value
	end

	local active = read_palette()
	M.timer = uv.new_timer()
	M.timer:start(1000, 1000, vim.schedule_wrap(function()
		local selected = read_palette()
		if selected == active then
			return
		end
		active = selected
		package.loaded["config.palette"] = nil
		pcall(vim.cmd.colorscheme, "tokyonight-moon")
	end))

	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function()
			if M.timer then
				M.timer:stop()
				M.timer:close()
				M.timer = nil
			end
		end,
	})
end

return M
