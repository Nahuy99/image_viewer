package main

import "vendor:sdl3/ttf"
import sdl "vendor:sdl3"


Vec2 :: [2]f32

win_size: [2]i32
img_original_size: Vec2
window_scale_factor: f32

current_image: ^sdl.Texture
right_image_info_text: ^ttf.Text
left_image_info_text: ^ttf.Text
text_engine : ^ttf.TextEngine
ui_font: ^ttf.Font
