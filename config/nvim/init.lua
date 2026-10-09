vim.g.mapleader = " "
vim.g.maplocalleader = " "
if vim.g.have_nerd_font == nil then
	vim.g.have_nerd_font = true
end

require("config.options")
require("config.keybinds")
require("config.filetypes")
require("config.python").setup()
require("config.lazy")
