package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"

running: bool = true
current_mouse_pos: Vec2
zoom_level: f32 = 1.0
pan_offset: Vec2
is_panning: bool
last_mouse_pos: Vec2

handle_input :: proc(renderer:^sdl.Renderer,window:^sdl.Window) {
	using fmt
    event: sdl.Event
	for sdl.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			running = false
		case .KEY_DOWN:
			if event.key.key == sdl.GetKeyFromScancode(.ESCAPE, nil, true) {
				running = false
			}		
            if event.key.key == sdl.GetKeyFromScancode(.R, nil, true) {
                zoom_level = 1.0 
                pan_offset = {0,0}
			}
            if event.key.key == sdl.GetKeyFromScancode(.F, nil, true) {
			    if sdl.GetWindowFullscreenMode(window) != nil{
                    sdl.SetWindowFullscreen(window,false)
                }else if sdl.GetWindowFullscreenMode(window) == nil{
                    sdl.SetWindowFullscreen(window,true)
                }
            }
		case .MOUSE_WHEEL:
            handle_zoom(event.wheel)

		case .DROP_FILE:
            if event.drop.data != nil{
                file := event.drop
                handle_drop_file(file.data,renderer) 
            }else if event.drop.data == nil{
                println("Erro ao carregar imagem largada: ", sdl.GetError())
            }
        case .MOUSE_BUTTON_DOWN:
            if event.button.button == 1{
                is_panning = true
                last_mouse_pos.y = f32(event.button.y)
                last_mouse_pos.x = f32(event.button.x)
            }
        case .MOUSE_BUTTON_UP:
            if event.button.button == 1{
                is_panning = false
            }
        case .MOUSE_MOTION:
            if is_panning{
                current_mouse_pos = Vec2{event.motion.x,event.motion.y}

                delta_x := current_mouse_pos.x - last_mouse_pos.x
                delta_y := current_mouse_pos.y - last_mouse_pos.y
                
                pan_offset.x += delta_x
                pan_offset.y += delta_y

                last_mouse_pos = current_mouse_pos
            }
		}
	}
}

handle_drop_file::proc(path:cstring,renderer:^sdl.Renderer){
    spath := strings.clone_from_cstring(path)
    current_image = load_image(renderer,spath)
    sdl.RenderClear(renderer)
}

handle_zoom:: proc(event:sdl.MouseWheelEvent){
    using event

    if y > 0{
        zoom_level *= 1.1
    }else if y < 0{
        zoom_level *= 0.9
    }
    zoom_level = max(0.1, min(10.0, zoom_level))
}
