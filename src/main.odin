package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import sdl "vendor:sdl3"
import "vendor:sdl3/image"
import "vendor:sdl3/ttf"

main :: proc() {
	using fmt

	load_config_file()

	ok := sdl.Init({.VIDEO, .EVENTS})
	if !ok {
		println("Error while creating window: ", sdl.GetError())
	}

	ok = ttf.Init()
	if !ok {
		println("Error while loading the ttf lib: ", sdl.GetError())
	}
	defer ttf.DestroyRendererTextEngine(text_engine)
	defer ttf.CloseFont(ui_font)
	defer ttf.DestroyText(left_image_info_text)
	defer ttf.DestroyText(right_image_info_text)

	window := sdl.CreateWindow("Image Viewer", 1280, 720, {.RESIZABLE, .HIGH_PIXEL_DENSITY})
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, nil)
	sdl.SetRenderVSync(renderer, 1)

	if renderer == nil {
		println("Error while creating renderer: ", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(renderer)

	load_font(renderer)

    // load via cli, or if you drag an image to the executable
	if len(os.args) > 1 {
		initial_path := os.args[1]
		current_image = load_image(renderer, initial_path)
		get_file_info(initial_path)
	}
    
    //main loop
	for running {
		free_all(context.temp_allocator)
		if current_image != nil {
			sdl.GetTextureSize(current_image, &img_original_size.x, &img_original_size.y)
		}

		handle_input(renderer, window)

		if should_redraw {
			render(renderer, current_image, window)
			should_redraw = false
		}
	}

}

load_image :: proc(renderer: ^sdl.Renderer, path: string) -> ^sdl.Texture {
	using fmt

	c_path := strings.clone_to_cstring(path, context.temp_allocator)

	surface := image.Load(c_path)

	if surface == nil {
		println("Error while loading image: ", sdl.GetError())
		return nil
	}
	defer sdl.DestroySurface(surface)

	texture := sdl.CreateTextureFromSurface(renderer, surface)
	if texture == nil {
		println("Error while creating texture: ", sdl.GetError())
		return nil
	}

	w, h: f32
	sdl.GetTextureSize(texture, &w, &h)
	img_original_size.x = w
	img_original_size.x = h

	return texture
}

calculate_display_size_with_zoom :: proc() -> Vec2 {

	scale_w := f32(win_size.x) / img_original_size.x
	scale_h := f32(win_size.y) / img_original_size.y

	scale := min(scale_w, scale_h)
	scale *= zoom_level

	display_w := img_original_size.x * scale
	display_h := img_original_size.y * scale

	return {display_w, display_h}
}

load_font :: proc(renderer: ^sdl.Renderer) {
	using fmt
	font_path := tprintf("%sassets/fonts/JetBrainsMonoNerdFont-Bold.ttf", base_path)

	text_engine = ttf.CreateRendererTextEngine(renderer)

	ui_font = ttf.OpenFont(
		strings.clone_to_cstring(font_path, context.temp_allocator),
		global_configs.text_size,
	)
	if ui_font == nil {
		println("Error while loading font: %s", sdl.GetError())
	}

	left_image_info_text = ttf.CreateText(text_engine, ui_font, "Arraste uma imagem", 0)
	right_image_info_text = ttf.CreateText(text_engine, ui_font, "100%", 0)

	text_color := global_configs.text_color

	ttf.SetTextColor(
		left_image_info_text,
		u8(text_color.r * 255),
		u8(text_color.g * 255),
		u8(text_color.b * 255),
		255,
	)
	ttf.SetTextColor(
		right_image_info_text,
		u8(text_color.r * 255),
		u8(text_color.g * 255),
		u8(text_color.b * 255),
		255,
	)
}

load_config_file :: proc() {
	config_path := fmt.tprintf("%sconfig.json", base_path)

	data, ok := os.read_entire_file(config_path)
	if !ok {
        fmt.println("Error while loading config.json, using default config")
		global_configs = default_configs
        return
	}

	defer delete(data)

	json.unmarshal(data, &global_configs)
}
