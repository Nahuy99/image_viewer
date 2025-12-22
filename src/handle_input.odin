package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"

running: bool = true

handle_input :: proc(renderer:^sdl.Renderer) {
	event: sdl.Event
	for sdl.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			running = false
		case .KEY_DOWN:
			if event.key.key == sdl.GetKeyFromScancode(.ESCAPE, nil, true) {
				running = false
			}
		case .MOUSE_WHEEL:
			wheel := event.wheel
			if wheel.y > 0 {
				zoom_level *= 1.1
			} else if wheel.y < 0 {
				zoom_level *= 0.9
			}
			zoom_level = max(0.1, min(10.0, zoom_level))

		case .DROP_FILE:
            if event.drop.data != nil{
                file := event.drop
                handle_drop_file(file.data,renderer) 
            }else if event.drop.data == nil{
                fmt.println("Erro ao carregar imagem largada: ", sdl.GetError())
            }
		}
	}
}

handle_drop_file::proc(path:cstring,renderer:^sdl.Renderer){
    spath := strings.clone_from_cstring(path)
    current_image = load_image(renderer,spath)
    sdl.RenderClear(renderer)
}
