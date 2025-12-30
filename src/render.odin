package main

import im "shared:imgui"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import im_sdlr "shared:imgui/imgui_impl_sdlrenderer3"
import sdl "vendor:sdl3"

render :: proc(renderer: ^sdl.Renderer, texture: ^sdl.Texture, window: ^sdl.Window) {
    bg_color := app.configs.ui.bg_color
    
    bg_hex := hex_string_to_u32(bg_color)

    r := u8((bg_hex >> 16)  & 0xFF)
    g := u8((bg_hex >> 8)  & 0xFF)
    b := u8((bg_hex >> 0) & 0xFF)
    a := u8(255)

	sdl.SetRenderDrawColor(renderer,r,g,b,a)
	sdl.RenderClear(renderer)

	sdl.GetWindowSize(window, &app.win_size.x, &app.win_size.y)

	app.display_size = calculate_display_size_with_zoom()

	base_x := (f32(app.win_size.x) - app.display_size.x) / 2
	base_y := (f32(app.win_size.y) - app.display_size.y) / 2

	destination_rec := sdl.FRect {
		x = base_x + pan_offset.x,
		y = base_y + pan_offset.y,
		w = app.display_size.x,
		h = app.display_size.y,
	}
 
	sdl.RenderTexture(renderer, texture, nil, &destination_rec)

    im.Render()
	im_sdlr.RenderDrawData(im.GetDrawData(), renderer)

	sdl.RenderPresent(renderer)
}

render_imgui :: proc(renderer: ^sdl.Renderer) {
	im_sdl.NewFrame()
	im_sdlr.NewFrame()
	im.NewFrame()

    if ui_is_visible{
        draw_top_ui()
        draw_bottom_ui()
    }
}

