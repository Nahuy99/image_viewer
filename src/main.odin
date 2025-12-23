package main

import "core:os"
import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import "vendor:sdl3/image"
import "vendor:sdl3/ttf"

main :: proc() {
	using fmt
	defer sdl.DestroyTexture(current_image)


	ok := sdl.Init({.VIDEO, .EVENTS})
	if !ok {
		println("Erro ao criar janela: ", sdl.GetError())
	}

	ok = ttf.Init()
	if !ok {
		println("Erro ao carregar biblioteca ttf: ", sdl.GetError())
	}
	defer ttf.DestroyRendererTextEngine(text_engine)
	defer ttf.CloseFont(ui_font)
    defer ttf.DestroyText(left_image_info_text)
	
    window := sdl.CreateWindow(
		"Image Viewer",
		1920,
		1080,
		{.BORDERLESS, .RESIZABLE, .HIGH_PIXEL_DENSITY},
	)
	defer sdl.DestroyWindow(window)


	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		println("erro ao criar renderer: ", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(renderer)

    load_font(renderer)

    if  len(os.args)>1{
        initial_path := os.args[1]

        current_image = load_image(renderer,initial_path)
        
        get_file_info(initial_path)
    }
	
    for running {
		free_all(context.temp_allocator)
		sdl.GetWindowSize(window, &win_size.x, &win_size.y)
		if current_image != nil {
			sdl.GetTextureSize(current_image, &img_original_size.x, &img_original_size.y)
		}
		handle_input(renderer, window)
		render(renderer, current_image)
	}

}

load_image :: proc(renderer: ^sdl.Renderer, path: string) -> ^sdl.Texture {
	using fmt

	c_path := strings.clone_to_cstring(path, context.temp_allocator)

	surface := image.Load(c_path)

	if surface == nil {
		println("Erro ao dar load na imagem: ", sdl.GetError())
		return nil
	}
	defer sdl.DestroySurface(surface)

	texture := sdl.CreateTextureFromSurface(renderer, surface)
	if texture == nil {
		println("Erro ao criar textura: ", sdl.GetError())
		return nil
	}
   
  	return texture
}

calculate_display_size_with_zoom :: proc() -> Vec2 {
	scale := f32(win_size.x) / img_original_size.x

	scale *= zoom_level

	display_w := img_original_size.x * scale
	display_h := img_original_size.y * scale

	return {display_w, display_h}
}

load_font :: proc(renderer:^sdl.Renderer) {
    using fmt
	base_path := sdl.GetBasePath()
	font_path := tprintf("%sassets/fonts/JetBrainsMonoNerdFont-Bold.ttf", base_path)

	text_engine = ttf.CreateRendererTextEngine(renderer)

	ui_font = ttf.OpenFont(strings.clone_to_cstring(font_path, context.temp_allocator), 26)
	if ui_font == nil {
		println("Erro ao carregar a fonte: %s", sdl.GetError())
	}

	left_image_info_text = ttf.CreateText(text_engine, ui_font, "Arraste uma imagem", 0)
    right_image_info_text = ttf.CreateText(text_engine,ui_font,"100%",0)

	ttf.SetTextColor(
		left_image_info_text,
		ui_bottom_bar_text.r,
		ui_bottom_bar_text.g,
		ui_bottom_bar_text.b,
		255,
	)
	ttf.SetTextColor(
		right_image_info_text,
		ui_bottom_bar_text.r,
		ui_bottom_bar_text.g,
		ui_bottom_bar_text.b,
		255,
	)
}
