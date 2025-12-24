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

base_path:= sdl.GetBasePath()

Config :: struct {
	bg_color:     [4]f32 `json:"background"`,
	ui_bar_color: [4]f32 `json:"ui_bar"`,
	text_color:   [4]f32 `json:"text"`,
    text_size: f32 `json:"text_size"`,
}

global_configs: Config
