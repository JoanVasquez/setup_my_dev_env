local M = {}
local enabled = false
local timer

function M.status()
	return enabled and "CAPS LOCK" or ""
end

function M.setup()
	if timer or vim.fn.has("linux") ~= 1 then
		return
	end

	local function update()
		local active = false
		-- Discover on each poll to handle keyboards being connected or removed.
		for _, path in ipairs(vim.fn.glob("/sys/class/leds/*::capslock/brightness", false, true)) do
			local file = io.open(path, "r")
			if file then
				local value = tonumber(file:read("*l")) or 0
				file:close()
				if value > 0 then
					active = true
					break
				end
			end
		end
		if enabled ~= active then
			enabled = active
			local lualine = package.loaded["lualine"]
			if lualine then
				lualine.refresh({ place = { "statusline" } })
			end
		end
	end

	update()
	timer = assert(vim.uv.new_timer())
	timer:start(500, 500, vim.schedule_wrap(function()
		if timer then
			update()
		end
	end))
	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function()
			timer:stop()
			timer:close()
			timer = nil
		end,
	})
end

return M
