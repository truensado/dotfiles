-- Colors
local catppuccin_palette = {
	rosewater = "#f5e0dc",
	flamingo = "#f2cdcd",
	pink = "#f5c2e7",
	mauve = "#cba6f7",
	red = "#f38ba8",
	maroon = "#eba0ac",
	peach = "#fab387",
	yellow = "#f9e2af",
	green = "#a6e3a1",
	teal = "#94e2d5",
	sky = "#89dceb",
	sapphire = "#74c7ec",
	blue = "#89b4fa",
	lavender = "#b4befe",
	text = "#cdd6f4",
	subtext1 = "#bac2de",
	subtext0 = "#a6adc8",
	overlay2 = "#9399b2",
	overlay1 = "#7f849c",
	overlay0 = "#6c7086",
	surface2 = "#585b70",
	surface1 = "#45475a",
	surface0 = "#313244",
	base = "#1e1e2e",
	mantle = "#181825",
	crust = "#11111b",
}
-- Plugins
-- full-border
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})
-- git
require("git"):setup()
-- zoxide
require("zoxide"):setup({
	update_db = true,
})
-- session
require("session"):setup({
	sync_yanked = true,
})
-- restore
require("restore"):setup({
	position = { "center", w = 70, h = 40 },
	show_confirm = true,
})
-- shell
require("custom-shell"):setup({
	history_path = "default",
	save_history = true,
})
-- yatline
require("yatline"):setup({
	section_separator = { open = "", close = "" },
	inverse_separator = { open = "", close = "" },
	part_separator = { open = "", close = "" },

	style_a = {
		fg = catppuccin_palette.mantle,
		bg_mode = {
			normal = catppuccin_palette.blue,
			select = catppuccin_palette.mauve,
			un_set = catppuccin_palette.red,
		},
	},
	style_b = { bg = catppuccin_palette.surface0, fg = catppuccin_palette.text },
	style_c = { bg = catppuccin_palette.base, fg = catppuccin_palette.text },

	permissions_t_fg = catppuccin_palette.green,
	permissions_r_fg = catppuccin_palette.yellow,
	permissions_w_fg = catppuccin_palette.red,
	permissions_x_fg = catppuccin_palette.sky,
	permissions_s_fg = catppuccin_palette.lavender,

	selected = { icon = "󰻭", fg = catppuccin_palette.yellow },
	copied = { icon = "", fg = catppuccin_palette.green },
	cut = { icon = "", fg = catppuccin_palette.red },

	total = { icon = "", fg = catppuccin_palette.yellow },
	succ = { icon = "", fg = catppuccin_palette.green },
	fail = { icon = "", fg = catppuccin_palette.red },
	found = { icon = "", fg = catppuccin_palette.blue },
	processed = { icon = "", fg = catppuccin_palette.green },

	tab_width = 20,
	tab_use_inverse = true,

	show_background = false,

	display_header_line = true,
	display_status_line = true,

	header_line = {
		left = {
			section_a = {
				{ type = "line", custom = false, name = "tabs", params = { "left" } },
			},
			section_b = {
				{ type = "coloreds", custom = false, name = "githead" },
			},
			section_c = {},
		},
		right = {
			section_a = {
				{ type = "string", custom = false, name = "tab_path" },
			},
			section_b = {
				{ type = "coloreds", custom = false, name = "task_workload" },
			},
			section_c = {
				{ type = "coloreds", custom = false, name = "task_states" },
			},
		},
	},

	status_line = {
		left = {
			section_a = {
				{ type = "string", custom = false, name = "tab_mode" },
			},
			section_b = {
				{ type = "string", custom = false, name = "hovered_size" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_name" },
				{ type = "coloreds", custom = false, name = "count" },
			},
		},
		right = {
			section_a = {
				{ type = "string", custom = false, name = "cursor_position" },
			},
			section_b = {
				{ type = "string", custom = false, name = "cursor_percentage" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_file_extension", params = { true } },
				{ type = "coloreds", custom = false, name = "permissions" },
			},
		},
	},
})
-- yatline-githead
require("yatline-githead"):setup({
	show_branch = true,
	branch_prefix = "",
	branch_symbol = "",
	branch_borders = "",

	commit_symbol = " ",

	show_behind_ahead = true,
	behind_symbol = " ",
	ahead_symbol = " ",

	show_stashes = true,
	stashes_symbol = " ",

	show_state = true,
	show_state_prefix = true,
	state_symbol = "󱅉",

	show_staged = true,
	staged_symbol = " ",

	show_unstaged = true,
	unstaged_symbol = " ",

	show_untracked = true,
	untracked_symbol = " ",

	prefix_color = catppuccin_palette.pink,
	branch_color = catppuccin_palette.pink,
	commit_color = catppuccin_palette.mauve,
	stashes_color = catppuccin_palette.teal,
	state_color = catppuccin_palette.lavender,
	staged_color = catppuccin_palette.green,
	unstaged_color = catppuccin_palette.yellow,
	untracked_color = catppuccin_palette.pink,
	ahead_color = catppuccin_palette.green,
	behind_color = catppuccin_palette.yellow,
})
