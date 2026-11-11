local state_home = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
local state_file = state_home .. "/quickshell/palette"

local function current_name()
	local file = io.open(state_file, "r")
	if not file then
		return "Crimson"
	end
	local name = file:read("*l")
	file:close()
	return name
end

local palettes = {
	Aurora = {
		bg = "#071321", panel = "#0c2135", selection = "#173a56",
		fg = "#edf7ff", muted = "#7895aa", blue = "#239ff3",
		cyan = "#74d8ff", green = "#6fe5ad", violet = "#b79cff",
		rose = "#f3a7d5", amber = "#ffd27d", coral = "#ff957a", red = "#ff6b85",
	},
	Crimson = {
		bg = "#18080e", panel = "#2a0e17", selection = "#4b1a29",
		fg = "#fff0f2", muted = "#b78a94", blue = "#ff536a",
		cyan = "#ff9aaa", green = "#70ddb0", violet = "#d3a4ff",
		rose = "#ff8fb3", amber = "#ffc66f", coral = "#ff806d", red = "#ff536a",
	},
	Sunset = {
		bg = "#170d05", panel = "#2c1909", selection = "#503017",
		fg = "#fff8ed", muted = "#b89c7d", blue = "#f49a18",
		cyan = "#ffd08b", green = "#9ed47b", violet = "#c7a1ff",
		rose = "#ffad91", amber = "#ffe1ac", coral = "#ff8d58", red = "#ff655d",
	},
	Forest = {
		bg = "#05130d", panel = "#0a2519", selection = "#144632",
		fg = "#eef8f1", muted = "#7eaa91", blue = "#64c8a0",
		cyan = "#72e2c0", green = "#24b76a", violet = "#b5a2ef",
		rose = "#efa8c8", amber = "#e6cf84", coral = "#ef967c", red = "#ed7085",
	},
	Violet = {
		bg = "#12091d", panel = "#251238", selection = "#44245e",
		fg = "#f7efff", muted = "#9d88b5", blue = "#aa75ef",
		cyan = "#cf9fff", green = "#72d7b1", violet = "#c38cff",
		rose = "#ef9ed5", amber = "#e9ca83", coral = "#ef907f", red = "#ef718e",
	},
}

return palettes[current_name()] or palettes.Crimson
