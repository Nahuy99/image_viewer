package main

import sdl "vendor:sdl3"
display_size : Vec2

render :: proc(renderer:^sdl.Renderer,texture:^sdl.Texture) {
	sdl.SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF)
	sdl.RenderClear(renderer)

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
	sdl.RenderPresent(renderer)
}
