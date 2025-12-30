package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import sdl "vendor:sdl3"

running: bool = true
current_mouse_pos: Vec2
pan_offset: Vec2
is_panning: bool
last_mouse_pos: Vec2

keybidings: map[string]sdl.Scancode

handle_input :: proc(renderer: ^sdl.Renderer, window: ^sdl.Window) {
	using fmt
	event: sdl.Event
	if sdl.WaitEvent(&event) {
		loop := true
		imgui_consumed := im_sdl.ProcessEvent(&event)
		if imgui_consumed {
			app.should_redraw = true
		}

		for loop {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .KEY_DOWN:
				#partial switch event.key.scancode {
				case keybidings["quit"]:
					running = false
				case keybidings["reset_view"]:
					reset_zoom()
				case keybidings["fullscreen"]:
                    set_fullscreen(window)
				case keybidings["hide_ui"]:
					show_or_hide_ui()
				}

			case .MOUSE_WHEEL:
				handle_zoom(event.wheel)
				app.should_redraw = true
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

				if imgui_consumed {
					app.should_redraw = true
				}

				if is_panning {
					delta := current_mouse_pos - last_mouse_pos
					pan_offset += delta
					last_mouse_pos = current_mouse_pos
					app.should_redraw = true
				}
			case .WINDOW_EXPOSED, .WINDOW_RESIZED, .WINDOW_PIXEL_SIZE_CHANGED:
				app.should_redraw = true
			}

			if !sdl.PollEvent(&event) {
				loop = false
			}
		}
	}
}

handle_drop_file :: proc(path: cstring, renderer: ^sdl.Renderer) {
	spath := strings.clone_from_cstring(path, context.temp_allocator)

	if app.current_image != nil {
		sdl.DestroyTexture(app.current_image)
	}

	app.current_image = load_image(renderer, spath)
	sdl.GetTextureSize(app.current_image, &img_original_size.x, &img_original_size.y)

	get_file_info(spath)
}

handle_zoom :: proc(event: sdl.MouseWheelEvent) {
	using event
	if y > 0 {
		app.zoom_level *= 1.1
	} else if y < 0 {
		app.zoom_level *= 0.9
	}
	app.zoom_level = max(0.1, min(10.0, app.zoom_level))

	//update_zoom_text(app.zoom_level)
}

update_zoom_text :: proc(zoom_level: f32) {
	zoom_percentage := zoom_level * 100
	app.zoom_text = fmt.tprintf("%0.f%%", zoom_percentage)
}

reset_zoom :: proc() {
	app.zoom_level = 1.0
	//update_zoom_text(app.zoom_level)
	pan_offset = {0, 0}
	app.should_redraw = true
}

get_file_info :: proc(path: string) {
	if len(app.img_info_text) > 0 {
        delete(app.img_info_text)
    }

    file, err := os.stat(path, context.temp_allocator)
	file_size_str :string
    if err == nil {
		if file.size < 1024 * 1024 {
            file_size_str = fmt.tprintf("%dKb", file.size / 1024)
		} else {
            file_size_str = fmt.tprintf("%0.1fM", f64(file.size) / (1024 * 1024))
		}
	}

	w, h: f32
	sdl.GetTextureSize(app.current_image, &w, &h)

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

	app.img_info_text = fmt.aprintf("%s %s %s", file_size, display_name, resolution)

	app.should_redraw = true
}

show_or_hide_ui :: proc() {
	if ui_is_visible {
		ui_is_visible = false
		app.should_redraw = true
	} else {
		ui_is_visible = true
		app.should_redraw = true
	}
}

string_to_scancode :: proc(key: string) -> sdl.Scancode {
	scancode := sdl.GetScancodeFromName(strings.clone_to_cstring(key, context.temp_allocator))

	if scancode != .UNKNOWN {
		return scancode
	}
	return .UNKNOWN
}

setup_bindings :: proc() {
	keybidings["fullscreen"] = string_to_scancode(app.configs.keybidings.fullscreen)
	keybidings["quit"] = string_to_scancode(app.configs.keybidings.quit)
	keybidings["hide_ui"] = string_to_scancode(app.configs.keybidings.hide_ui)
	keybidings["reset_view"] = string_to_scancode(app.configs.keybidings.reset_view)
}

set_fullscreen :: proc(window: ^sdl.Window) {
	flags := sdl.GetWindowFlags(window)
	is_fullscreen := (flags & sdl.WINDOW_FULLSCREEN) != {}
	sdl.SetWindowFullscreen(window, !is_fullscreen)
}
