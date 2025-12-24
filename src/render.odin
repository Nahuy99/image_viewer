package main

import sdl "vendor:sdl3"
import "vendor:sdl3/ttf"
display_size: Vec2

ui_elements :: struct {
	w, h: f32,
}

ui_bottom_bar: ui_elements = {
	h = 50,
}

render :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture, window: ^sdl.Window) {

	bg_color := global_configs.bg_color
	sdl.SetRenderDrawColor(
		renderer,
		u8(bg_color.r * 255),
		u8(bg_color.g * 255),
		u8(bg_color.b * 255),
		255,
	)
	sdl.RenderClear(renderer)

	sdl.GetWindowSize(window, &win_size.x, &win_size.y)

	display_size = calculate_display_size_with_zoom()

	base_x := (f32(win_size.x) - display_size.x) / 2
	base_y := (f32(win_size.y) - display_size.y) / 2

	destination_rec := sdl.FRect {
		x = base_x + pan_offset.x,
		y = base_y + pan_offset.y,
		w = display_size.x,
		h = display_size.y,
	}

	sdl.RenderTexture(renderer, texture, nil, &destination_rec)

	ui_rec := sdl.FRect {
		x = 0,
		y = f32(win_size.y) - ui_bottom_bar.h,
		w = f32(win_size.x),
		h = ui_bottom_bar.h,
	}

	ui_color := global_configs.ui_bar_color
	
    sdl.SetRenderDrawColor(
		renderer,
		u8(ui_color.r * 255),
		u8(ui_color.g * 255),
		u8(ui_color.b * 255),
		255,
	)
	sdl.RenderFillRect(renderer, &ui_rec)

	ttf.DrawRendererText(left_image_info_text, 10, f32(win_size.y) - (ui_bottom_bar.h - 10))

	zoom_text_w: i32
	ttf.GetTextSize(right_image_info_text, &zoom_text_w, nil)
	ttf.DrawRendererText(
		right_image_info_text,
		f32(win_size.x) - f32(zoom_text_w) - 10,
		f32(win_size.y) - (ui_bottom_bar.h - 10),
	)

	sdl.RenderPresent(renderer)
}
