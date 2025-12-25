package main

import sdl "vendor:sdl3"
import "vendor:sdl3/ttf"

UI_HIDE_TIME :: 3.0
UI_SLIDE_SPEED :: 500.0

ui_slide_offset: f32 
ui_is_visible: bool = true

right_image_info_text: ^ttf.Text
left_image_info_text: ^ttf.Text
text_engine: ^ttf.TextEngine
ui_font: ^ttf.Font

ui_elements :: struct {
	w, h: f32,
}

ui_bottom_bar: ui_elements = {
	h = 50,
}

draw_ui :: proc(renderer: ^sdl.Renderer) {
    if !ui_is_visible do return

    current_y := f32(win_size.y) - ui_bottom_bar.h + ui_slide_offset

	ui_rec := sdl.FRect {
		x = 0,
		y = current_y,
		w = f32(win_size.x),
		h = ui_bottom_bar.h,
	}

	ui_color := global_configs.ui.ui_bar_color
    
	sdl.SetRenderDrawColor(
		renderer,
		u8(ui_color.r * 255),
		u8(ui_color.g * 255),
		u8(ui_color.b * 255),
		255,
	)
    
	sdl.RenderFillRect(renderer, &ui_rec)

    text_y := current_y + 10

	ttf.DrawRendererText(left_image_info_text, 10,text_y)

	zoom_text_w: i32

	ttf.GetTextSize(right_image_info_text, &zoom_text_w, nil)
	ttf.DrawRendererText(
		right_image_info_text,
		f32(win_size.x) - f32(zoom_text_w) - 10,
		text_y,
	)
}
