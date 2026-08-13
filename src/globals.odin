package main

import "core:encoding/json"
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
	configs:             App_Config,
	base_path:           cstring,
	font_path:           cstring,
	should_redraw:       bool,
	ui_font:             ^im.Font,
	img_info_text:       string,
	zoom_level:          f32,
	zoom_text:           string,
	display_size:        Vec2,
	current_image:       ^sdl.Texture,
	current_image_index: int,
	img_pool:            [dynamic]^sdl.Texture,
	show_config:         bool,
	show_details:        bool,
}

app: App

init_app :: proc(app: ^App) {
	app.zoom_level = 1.0
	app.should_redraw = true
	app.current_image_index = 0
}

App_Config :: struct {
	ui:         UI_config `json:"ui"`,
	keybidings: Keybidings_Config `json:"keybinds"`,
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

UI_config :: struct {
	bg_color:          string `json:"background"`,
	bg_color_dark:     string `json:"background_dark"`,
	ui_bar_color:      string `json:"ui_bar"`,
	ui_bar_color_dark: string `json:"ui_bar_dark"`,
	text_color:        string `json:"text"`,
	text_color_dark:   string `json:"text_dark"`,
	text_size:         f32 `json:"text_size"`,
	font:              string `json:"font"`,
	dark_mode:         bool `json:"dark_mode"`,
}

default_configs: App_Config = {
	ui = UI_config {
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
}
