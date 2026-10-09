return {
	"akinsho/bufferline.nvim",
	dependencies = { "moll/vim-bbye", "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			mode = "buffers",
			close_command = "Bdelete %d",
			right_mouse_command = "Bdelete %d",
			diagnostics = "nvim_lsp",
			diagnostics_indicator = function(count)
				return " " .. count
			end,
			separator_style = "slant",
			indicator = { style = "underline" },
			show_buffer_close_icons = false,
			modified_icon = "●",
			truncate_names = true,
			show_close_icon = false,
			always_show_bufferline = false,
			max_name_length = 24,
			sort_by = "insert_at_end",
			offsets = {
				{ filetype = "neo-tree", text = "󰙅  EXPLORER", text_align = "center", separator = true },
			},
		},
	},
}
