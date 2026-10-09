-- ============================================================================
-- Editor options
-- ============================================================================

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorlineopt = "number,line"
opt.numberwidth = 4

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.showmode = false
opt.cmdheight = 1
opt.laststatus = 3

-- Better completion experience
opt.completeopt = { "menu", "menuone", "noselect" }

-- Clipboard
opt.clipboard = "unnamedplus"

-- Files / encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Editing behavior
opt.backspace = { "indent", "eol", "start" }
opt.whichwrap:append("<,>,[,],h,l")

-- Performance
opt.updatetime = 250
opt.timeoutlen = 400

-- Undo
opt.undofile = true

-- Recover unsaved edits after a crash; keep backups only during writes
opt.swapfile = true
opt.backup = false
opt.writebackup = true

-- Better command completion
opt.wildmenu = true
opt.wildmode = "longest:full,full"

-- Mouse support
opt.mouse = "a"

-- Prevent horizontal scrolling for long lines
opt.sidescroll = 1

-- Highlight matching brackets
opt.showmatch = true
opt.matchtime = 2

-- Allow hidden buffers
opt.hidden = true

-- Consistent, understated UI chrome
opt.background = "dark"
opt.pumheight = 12
opt.winblend = 0
opt.pumblend = 0
opt.fillchars:append({ eob = " ", diff = "╱", vert = "│", horiz = "─", horizup = "┴", horizdown = "┬", vertleft = "┤", vertright = "├", verthoriz = "┼" })
opt.shortmess:append("I")
if vim.fn.exists("+winborder") == 1 then
	opt.winborder = "rounded"
end
