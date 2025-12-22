package main

import sdl "vendor:sdl3"

render :: proc(renderer:^sdl.Renderer,texture:^sdl.Texture) {
	sdl.SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF)
	sdl.RenderClear(renderer)

	display_size := calculate_display_size_with_zoom()

	destination_rec := sdl.FRect {
		x = (f32(win_size.x) - display_size.x) / 2,
		y = (f32(win_size.y) - display_size.y) / 2,
		w = display_size.x,
		h = display_size.y,
	}

	sdl.RenderTexture(renderer, texture, nil, &destination_rec)
	sdl.RenderPresent(renderer)
}
