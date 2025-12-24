package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import sdl "vendor:sdl3"
import "vendor:sdl3/ttf"

running: bool = true
current_mouse_pos: Vec2
zoom_level: f32 = 1.0
pan_offset: Vec2
is_panning: bool
last_mouse_pos: Vec2

file_size_str: string

handle_input :: proc(renderer: ^sdl.Renderer, window: ^sdl.Window) {
	using fmt
	event: sdl.Event
	if sdl.WaitEvent(&event) {
		loop := true
		for loop {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .KEY_DOWN:
				#partial switch event.key.scancode {
				case .ESCAPE:
					running = false
				case .F:
                    reset_zoom()
				case .F11, .RETURN:
					flags := sdl.GetWindowFlags(window)
					is_fullscreen := (flags & sdl.WINDOW_FULLSCREEN) != {}
					sdl.SetWindowFullscreen(window, !is_fullscreen)
				}

			case .MOUSE_WHEEL:
				handle_zoom(event.wheel)
				should_redraw = true

			case .DROP_FILE:
                reset_zoom()
				if event.drop.data != nil {
					file := event.drop
					handle_drop_file(file.data, renderer)
				} else if event.drop.data == nil {
					println("Erro ao carregar imagem largada: ", sdl.GetError())
				}
			case .MOUSE_BUTTON_DOWN:
				if event.button.button == 1 {
					is_panning = true
					last_mouse_pos.y = f32(event.button.y)
					last_mouse_pos.x = f32(event.button.x)
				}
			case .MOUSE_BUTTON_UP:
				if event.button.button == 1 {
					is_panning = false
				}
			case .MOUSE_MOTION:
				current_mouse_pos = Vec2{event.motion.x, event.motion.y}
				if is_panning {
					delta := current_mouse_pos - last_mouse_pos
					pan_offset += delta
					last_mouse_pos = current_mouse_pos
					should_redraw = true
				}
			case .WINDOW_EXPOSED, .WINDOW_RESIZED, .WINDOW_PIXEL_SIZE_CHANGED:
				should_redraw = true
			}

			if !sdl.PollEvent(&event) {
				loop = false
			}
		}
	}
}

handle_drop_file :: proc(path: cstring, renderer: ^sdl.Renderer) {
	spath := strings.clone_from_cstring(path, context.temp_allocator)

	if current_image != nil {
		sdl.DestroyTexture(current_image)
	}

	current_image = load_image(renderer, spath)
    sdl.GetTextureSize(current_image,&img_original_size.x,&img_original_size.y)

	get_file_info(spath)
}

handle_zoom :: proc(event: sdl.MouseWheelEvent) {
	using event
	if y > 0 {
		zoom_level *= 1.1
	} else if y < 0 {
		zoom_level *= 0.9
	}
	zoom_level = max(0.1, min(10.0, zoom_level))

	update_zoom_text(zoom_level)
}

update_zoom_text :: proc(zoom_legel: f32) {
	zoom_percentage := zoom_level * 100
	zoom_text := fmt.tprintf("%0.f%%", zoom_percentage)
	ttf.SetTextString(
		right_image_info_text,
		strings.clone_to_cstring(zoom_text, context.temp_allocator),
		0,
	)
}

reset_zoom :: proc() {
	zoom_level = 1.0
	update_zoom_text(zoom_level)
	pan_offset = {0, 0}
	should_redraw = true
}

get_file_info :: proc(path: string) {
	file, err := os.stat(path, context.temp_allocator)
	if err == nil {
		if file.size < 1024 * 1024 {
			file_size_str = fmt.tprintf("%dKb", file.size / 1024)
		} else {
			file_size_str = fmt.tprintf("%0.1fM", f64(file.size) / (1024 * 1024))
		}
	}

	w, h: f32
	sdl.GetTextureSize(current_image, &w, &h)

	resolution := fmt.tprintf("%vx%v", w, h)
	file_size := file_size_str
	max_file_name := 15
	file_name := filepath.base(path)
	file_extention := filepath.ext(path)
	file_stem := filepath.stem(file_name)

	display_name := file_name

	if len(file_stem) > max_file_name {
		display_name = fmt.tprintf(
			"%s...%s%s",
			file_stem[:10],
			file_stem[len(file_stem) - 3:],
			file_extention,
		)

	}

	img_string := fmt.tprintf("%s %s %s", file_size, display_name, resolution)

	ttf.SetTextString(
		left_image_info_text,
		strings.clone_to_cstring(img_string, context.temp_allocator),
		0,
	)
	should_redraw = true
}
