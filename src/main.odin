package main

import "core:fmt"
import sdl "vendor:sdl3"
import sdli "vendor:sdl3/image"

main :: proc() {
	using fmt

	ok := sdl.Init({.VIDEO, .EVENTS})
	if !ok {
		println("erro ao criar janela")
	}

	window := sdl.CreateWindow("Image Viewer", 1920, 1080, {.BORDERLESS,.RESIZABLE,.HIGH_PIXEL_DENSITY})
	defer sdl.DestroyWindow(window)

    renderer := sdl.CreateRenderer(window, nil)
    if renderer == nil{
        println("erro ao criar renderer: ", sdl.GetError())
        return 
    }
	defer sdl.DestroyRenderer(renderer)

    texture := load_image(renderer,"/home/nahuel/Pictures/wallpapers/cities/wp3594964-new-york-city-4k-wallpapers.jpg")
    defer sdl.DestroyTexture(texture)

    img_w,img_h: f32
    sdl.GetTextureSize(texture,&img_w,&img_h)
 
    running := true
	for running {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .KEY_DOWN:
				if event.key.key == sdl.GetKeyFromScancode(.ESCAPE,nil,true) {
					running = false
				}
			}
		}
		sdl.SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xFF)
		sdl.RenderClear(renderer)
        
        destination_rec:= sdl.FRect{
            x = (1920 - img_w) / 2,
            y = (1080 - img_h) / 2,
            w = img_w,
            h = img_h,
        }
        
        sdl.RenderTexture(renderer,texture,nil,&destination_rec)

		sdl.RenderPresent(renderer)
	}
}

load_image::proc(renderer:^sdl.Renderer,path:string)-> ^sdl.Texture{
    using fmt
    surface := sdli.Load(cstring(raw_data(path)))
    if surface == nil{
        println("Erro ao dar load na imagem:",sdl.GetError())
        return nil
    }
    defer sdl.DestroySurface(surface)

    texture := sdl.CreateTextureFromSurface(renderer,surface)
    if texture == nil {
        println("Erro ao criar textura: ",sdl.GetError())
        return nil
    }

    return texture
}
