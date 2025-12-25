package main

import sdl "vendor:sdl3"

display_size: Vec2
current_image: ^sdl.Texture

render :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture, window: ^sdl.Window) {

	bg_color := global_configs.ui.bg_color
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

    draw_ui(renderer)

	sdl.RenderPresent(renderer)
}
