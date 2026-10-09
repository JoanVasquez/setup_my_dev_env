local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map({ "n", "v" }, "<Space>", "<Nop>", "Leader")
map("n", "<C-s>", "<cmd>write<cr>", "Save file")
map("n", "<leader>sn", require("config.buffers").save_without_formatting, "Save without formatting")
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlights")
map("n", "n", "nzzzv", "Next search match")
map("n", "N", "Nzzzv", "Previous search match")
for key, direction in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
	map("n", "<C-" .. key .. ">", "<cmd>wincmd " .. direction .. "<cr>", "Focus " .. direction .. " window")
end
map("x", "p", '"_dP', "Paste without replacing register")
map("n", "<Tab>", "<cmd>bnext<cr>", "Next buffer")
map("n", "<S-Tab>", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "<leader>x", "<cmd>Bdelete<cr>", "Close buffer")
map("n", "<leader>a", function()
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buflisted and vim.bo[buf].filetype ~= "neo-tree" then
			if vim.bo[buf].modified then
				vim.notify("Save modified buffers before closing all buffers", vim.log.levels.WARN)
				return
			end
			table.insert(buffers, buf)
		end
	end
	for _, buf in ipairs(buffers) do
		vim.cmd("Bdelete " .. buf)
	end
end, "Close all saved buffers")
map("n", "<leader>cd", vim.cmd.Ex, "Browse current directory")
map("n", "<leader>wd", "<cmd>close<cr>", "Close window")
map("n", "<leader>wv", "<cmd>vsplit<cr>", "Split vertically")
map("n", "<leader>ws", "<cmd>split<cr>", "Split horizontally")
map("n", "<leader>w=", "<C-w>=", "Equalize windows")
map("n", "<leader>tw", function()
	vim.opt_local.wrap = not vim.opt_local.wrap:get()
end, "Toggle line wrapping")
