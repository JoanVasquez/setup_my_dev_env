local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if vim.fn.filereadable(lazypath .. "/lua/lazy/init.lua") == 0 then
	-- An interrupted clone must not count as a working plugin manager.
	local staging = lazypath .. ".install-" .. vim.fn.getpid()
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", staging })
	if vim.v.shell_error ~= 0 then
		error("Failed to clone lazy.nvim:\n" .. out)
	end
	if (vim.uv or vim.loop).fs_stat(lazypath) then
		local backup = lazypath .. ".backup-" .. os.time() .. "-" .. vim.fn.getpid()
		assert((vim.uv or vim.loop).fs_rename(lazypath, backup))
	end
	assert((vim.uv or vim.loop).fs_rename(staging, lazypath))
end
-- Lazy writes its lockfile after installs/updates. Seed the pinned manifest
-- once into user state, so plugin operations cannot mutate the linked checkout.
local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
if vim.fn.filereadable(lockfile) == 0 then
	local seed = vim.fn.stdpath("config") .. "/lazy-lock.json"
	if vim.fn.filereadable(seed) == 1 then
		vim.fn.mkdir(vim.fn.fnamemodify(lockfile, ":h"), "p")
		vim.fn.writefile(vim.fn.readfile(seed), lockfile)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	lockfile = lockfile,
	spec = {
		{ import = "plugins" },
	},
	change_detection = { notify = false },
})
