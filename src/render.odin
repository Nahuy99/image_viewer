package main

import im "shared:odin-imgui"
import im_sdl "shared:odin-imgui/imgui_impl_sdl3"
import im_sdlr "shared:odin-imgui/imgui_impl_sdlrenderer3"
import sdl "vendor:sdl3"

render :: proc(renderer: ^sdl.Renderer, window: ^sdl.Window) {
	bg_color := app.dark_mode ? app.configs.ui.bg_color_dark : app.configs.ui.bg_color
	bg_hex := hex_string_to_u32(bg_color)

	r := u8((bg_hex >> 16) & 0xFF)
	g := u8((bg_hex >> 8) & 0xFF)
	b := u8((bg_hex >> 0) & 0xFF)
	a := u8(255)

	sdl.SetRenderDrawColor(renderer, r, g, b, a)
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

	if len(app.images) > 0 do sdl.RenderTexture(renderer, app.images[app.current_image].image, nil, &destination_rec)

	im.Render()
	im_sdlr.RenderDrawData(im.GetDrawData(), renderer)
	sdl.RenderPresent(renderer)
}

render_imgui :: proc(renderer: ^sdl.Renderer) {
	im_sdl.NewFrame()
	im_sdlr.NewFrame()
	im.NewFrame()

	if ui_is_visible {

		im.PushFontFloat(app.ui_font, app.configs.ui.text_size)
		if app.show_keys do draw_keybinds()
		if app.show_config do draw_config_ui()
		if app.show_details do draw_detail_view()
		draw_bottom_ui()

		im.PopFont()
	}
}
