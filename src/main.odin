package main

import "core:fmt"
import sdl "vendor:sdl3"
import sdli "vendor:sdl3/image"

current_image:^sdl.Texture

main :: proc() {
	using fmt
	defer sdl.DestroyTexture(current_image)
	
    ok := sdl.Init({.VIDEO, .EVENTS})
	if !ok {
		println("erro ao criar janela")
	}

	window := sdl.CreateWindow(
		"Image Viewer",
		1920,
		1080,
		{.BORDERLESS,.RESIZABLE, .HIGH_PIXEL_DENSITY},
	)
	defer sdl.DestroyWindow(window)
   
    icon:= sdli.Load("~/dev/Odin/image_viewer/examples/icon.png")
    sdl.SetWindowIcon(window,icon)

	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		println("erro ao criar renderer: ", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(renderer)

	for running {
		sdl.GetWindowSize(window, &win_size.x, &win_size.y)
	    sdl.GetTextureSize(current_image, &img_original_size.x, &img_original_size.y)
		handle_input(renderer,window)
        render(renderer,current_image)
	}


}

load_image :: proc(renderer: ^sdl.Renderer, path: string) -> ^sdl.Texture {
	using fmt
	surface := sdli.Load(cstring(raw_data(path)))
	if surface == nil {
		println("Erro ao dar load na imagem:", sdl.GetError())
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


