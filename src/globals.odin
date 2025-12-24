package main

import sdl "vendor:sdl3"
import "vendor:sdl3/ttf"


Vec2 :: [2]f32

win_size: [2]i32
img_original_size: Vec2
window_scale_factor: f32

current_image: ^sdl.Texture
right_image_info_text: ^ttf.Text
left_image_info_text: ^ttf.Text
text_engine: ^ttf.TextEngine
ui_font: ^ttf.Font

should_redraw := true

base_path := sdl.GetBasePath()

Config :: struct {
	bg_color:     [4]f32 `json:"background"`,
	ui_bar_color: [4]f32 `json:"ui_bar"`,
	text_color:   [4]f32 `json:"text"`,
	text_size:    f32 `json:"text_size"`,
}

global_configs: Config
default_configs: Config = {
	bg_color     = {1.0, 1.0, 0.918, 1.0},
	ui_bar_color = {0.706, 0.333, 0.333, 1.0},
	text_color   = {0.886, 0.886, 0.820, 1.0},
	text_size    = 26.0,
}
