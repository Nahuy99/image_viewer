package main

import im "shared:odin-imgui"
import sdl "vendor:sdl3"

Vec2 :: [2]f32

img_original_size: Vec2

App :: struct {
	window:              ^sdl.Window,
	dark_mode:           bool,
	window_scale_factor: f32,
	renderer:            ^sdl.Renderer,
	win_size:            [2]i32,
	display_size:        Vec2,
	configs:             App_Config,
	config_file_path:    string,
	base_path:           string,
	font_path:           string,
	should_redraw:       bool,
	ui_font:             ^im.Font,
	zoom_level:          f32,
	zoom_text:           string,
	images:              [dynamic]Image,
	current_image:       int,
	show_config:         bool,
	show_details:        bool,
	show_keys:           bool,
}

Image :: struct {
	image: ^sdl.Texture,
	index: int,
	info:  string,
	size:  Vec2,
}

app: App

init_app :: proc(app: ^App) {
	app.images = make([dynamic]Image)
	app.zoom_level = 1.0
	app.should_redraw = true
	app.current_image = 0
	app.show_keys = true
}

App_Config :: struct {
	ui:           UI_Config `json:"ui"`,
	keybidings:   Keybidings_Config `json:"keybinds"`,
	colors:       Colors_Config `json:colors`,
	bar_color:    u32,
	text_color:   u32,
	shadow_color: u32,
	bkg_color:    string,
}

Colors_Config :: struct {
	black:   string `json:black`,
	cinder:  string `json:cinder`,
	ember:   string `json:ember`,
	brass:   string `json:brass`,
	sap:     string `json:sap`,
	frost:   string `json:frost`,
	fg:      string `json:fg`,
	fg_dim:  string `json:fg_dim`,
	comment: string `json:comment`,
	gutter:  string `json:gutter`,
	bg_deep: string `json:bg_deep`,
	bg0:     string `json:bg0`,
	bg1:     string `json:bg1`,
	bg2:     string `json:bg2`,
	bg3:     string `json:bg3`,
	bg4:     string `json:bg4`,
	bg5:     string `json:bg5`,
	error:   string `json:error`,
	warning: string `json:warning`,
	ok:      string `json:ok`,
	hint:    string `json:hint`,
	info:    string `json:info`,
}

Keybidings_Config :: struct {
	fullscreen:       string `json:"fullscreen"`,
	hide_ui:          string `json:"hide_ui"`,
	quit:             string `json:"quit"`,
	reset_view:       string `json:"reset_view"`,
	next_image:       string `json:"next_image"`,
	prev_image:       string `json:"prev_image"`,
	detailed_view:    string `json:"detailed_view"`,
	toggle_dark_mode: string `json:"toggle_dark_mode"`,
}

UI_Config :: struct {
	bg_color:          string `json:"background"`,
	bg_color_dark:     string `json:"background_dark"`,
	ui_bar_color:      string `json:"ui_bar"`,
	ui_bar_color_dark: string `json:"ui_bar_dark"`,
	text_color:        string `json:"text"`,
	text_color_dark:   string `json:"text_dark"`,
	font:              string `json:"font"`,
	dark_mode:         bool `json:"dark_mode"`,
	text_size:         f32 `json:"text_size"`,
}

default_configs: App_Config = {
	ui = UI_Config {
		bg_color = "FFFFEA",
		bg_color_dark = "171312",
		ui_bar_color = "BF5E5E",
		ui_bar_color_dark = "f4a21c",
		text_color = "FFFFEA",
		text_color_dark = "171312",
		text_size = 26.0,
		font = "HomeVideo-BLG6G.ttf",
		dark_mode = false,
	},
	keybidings = Keybidings_Config {
		fullscreen = "F",
		hide_ui = "H",
		quit = "ESCAPE",
		reset_view = "R",
		toggle_dark_mode = "G",
		detailed_view = "D",
		next_image = "N",
		prev_image = "P",
	},
	colors = Colors_Config {
		black = "201b19",
		cinder = "d1766e",
		ember = "ea9875",
		brass = "fcba81",
		sap = "99af6b",
		frost = "4e89a2",
		fg = "e6d5c2",
		fg_dim = "a09384",
		comment = "73665b",
		gutter = "4e4641",
		bg_deep = "0f0c0a",
		bg0 = "171311",
		bg1 = "201b19",
		bg2 = "2a2422",
		bg3 = "362f2c",
		bg4 = "463e3a",
		bg5 = "5a504c",
		error = "d25780",
		warning = "f4a21c",
		ok = "43b16a",
		hint = "20c9cb",
		info = "58bdff",
	},
}

free_config_varialbes :: proc() {
	delete(app.configs.colors.bg0)
	delete(app.configs.colors.bg1)
	delete(app.configs.colors.bg2)
	delete(app.configs.colors.bg3)
	delete(app.configs.colors.bg4)
	delete(app.configs.colors.bg5)
	delete(app.configs.colors.bg_deep)
	delete(app.configs.colors.black)
	delete(app.configs.colors.brass)
	delete(app.configs.colors.cinder)
	delete(app.configs.colors.comment)
	delete(app.configs.colors.ember)
	delete(app.configs.colors.error)
	delete(app.configs.colors.fg)
	delete(app.configs.colors.fg_dim)
	delete(app.configs.colors.frost)
	delete(app.configs.colors.gutter)
	delete(app.configs.colors.hint)
	delete(app.configs.colors.info)
	delete(app.configs.colors.ok)
	delete(app.configs.colors.sap)
	delete(app.configs.colors.warning)

	delete(app.configs.ui.bg_color)
	delete(app.configs.ui.bg_color_dark)
	delete(app.configs.ui.ui_bar_color)
	delete(app.configs.ui.ui_bar_color_dark)
	delete(app.configs.ui.text_color)
	delete(app.configs.ui.text_color_dark)
	delete(app.configs.ui.font)

	delete(app.configs.keybidings.fullscreen)
	delete(app.configs.keybidings.hide_ui)
	delete(app.configs.keybidings.quit)
	delete(app.configs.keybidings.reset_view)
	delete(app.configs.keybidings.next_image)
	delete(app.configs.keybidings.prev_image)
	delete(app.configs.keybidings.detailed_view)
	delete(app.configs.keybidings.toggle_dark_mode)
}

setup_colors :: proc() {
	app.configs.bkg_color = app.dark_mode ? app.configs.ui.bg_color_dark : app.configs.colors.fg
	app.configs.bar_color =
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.colors.frost) : imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)
	app.configs.text_color =
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.colors.fg) : imgui_hex_string_to_u32(app.configs.colors.fg)
	app.configs.shadow_color =
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.colors.bg4) : imgui_hex_string_to_u32(app.configs.ui.bg_color_dark)
}
