package main

import sdl "vendor:sdl3"

Vec2 :: [2]f32

win_size: [2]i32
img_original_size: Vec2
window_scale_factor: f32

should_redraw := true

base_path := sdl.GetBasePath()

App_Config :: struct {
    ui:         UI_config `json:"ui"`,
	keybidings: Keybidings_Config `json:"keybinds"`,
}

Keybidings_Config :: struct {
    fullscreen: string `json:"fullscreen"`,
    hide_ui: string `json:"hide_ui"`,
    quit: string `json:"quit"`,
    reset_view: string `json:"reset_view"`,
}

UI_config :: struct {
	bg_color:     [4]f32 `json:"background"`,
	ui_bar_color: [4]f32 `json:"ui_bar"`,
	text_color:   [4]f32 `json:"text"`,
	text_size:    f32 `json:"text_size"`,
}


global_configs: App_Config
default_configs: App_Config = {
	ui = UI_config{
		bg_color = {1.0, 1.0, 0.918, 1.0},
		ui_bar_color = {0.706, 0.333, 0.333, 1.0},
		text_color = {0.886, 0.886, 0.820, 1.0},
		text_size = 26.0,
	},
    keybidings = Keybidings_Config{
        fullscreen = "F11"
    }
}
