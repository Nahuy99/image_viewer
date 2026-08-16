package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:time"
import im_sdl "shared:odin-imgui/imgui_impl_sdl3"
import sdl "vendor:sdl3"

running: bool = true
current_mouse_pos: Vec2
pan_offset: Vec2
is_panning: bool
last_mouse_pos: Vec2

keybidings: map[string]sdl.Scancode

handle_input :: proc(renderer: ^sdl.Renderer, window: ^sdl.Window) {
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
				case keybidings["next_image"]:
					next_image()
				case keybidings["prev_image"]:
					previous_image()
				case keybidings["detailed_view"]:
					app.show_details = !app.show_details
				case keybidings["toggle_dark_mode"]:
					toggle_dark_mode()
				case .C:
					app.show_config = !app.show_config
				case .K:
					app.show_keys = !app.show_keys
				case .B:
					app.show_side_ui = !app.show_side_ui
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
					fmt.println("Erro ao carregar imagem largada: ", sdl.GetError())
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
	dir := os.is_dir(spath)
	if dir do load_dir_images(renderer, spath)
	else do load_image(renderer, spath)
}

handle_zoom :: proc(event: sdl.MouseWheelEvent) {
	if event.y > 0 {
		app.zoom_level *= 1.1
	} else if event.y < 0 {
		app.zoom_level *= 0.9
	}
	app.zoom_level = max(0.1, min(10.0, app.zoom_level))
}

update_zoom_text :: proc(zoom_level: f32) {
	zoom_percentage := zoom_level * 100
	app.zoom_text = fmt.tprintf("%0.f%%", zoom_percentage)
}

reset_zoom :: proc() {
	app.zoom_level = 1.0
	pan_offset = {0, 0}
	app.should_redraw = true
}

get_file_info :: proc(path: string, image: ^Image) -> Image_Info {
	info: Image_Info
	// file load
	file, err := os.stat(path, context.temp_allocator)
	// size
	file_size_str: string

	if err == nil {
		if file.size < 1024 * 1024 {
			file_size_str = fmt.tprintf("%dKb", file.size / 1024)
		} else {
			file_size_str = fmt.tprintf("%0.1fM", f64(file.size) / (1024 * 1024))
		}
	}
	info.size = strings.clone_to_cstring(file_size_str, context.allocator)


	// resolution
	w, h: f32
	sdl.GetTextureSize(image.image, &w, &h)
	info.resolution = fmt.caprintf("%vx%v", w, h)

	//name
	max_file_name := 25
	file_name := filepath.base(path)
	file_extention := filepath.ext(path)
	file_stem := filepath.stem(file_name)
	formated_ext, _ := strings.remove(file_extention, ".", 1, context.temp_allocator)
	info.ext = strings.clone_to_cstring(formated_ext, context.allocator)

	info.name = strings.clone_to_cstring(file_stem, context.allocator)

	//date
	year, month, day := time.date(file.modification_time)
	hour, min, sec := time.clock_from_time(file.modification_time)

	info.modification = fmt.caprintf(
		"Last Modified: %d-%02d-%02d %02d:%02d:%02d",
		year,
		int(month),
		day,
		hour,
		min,
		sec,
	)
	//reuzing the variables from modified
	year, month, day = time.date(file.creation_time)
	hour, min, sec = time.clock_from_time(file.creation_time)

	info.created = fmt.caprintf(
		"Created: %d-%02d-%02d %02d:%02d:%02d",
		year,
		int(month),
		day,
		hour,
		min,
		sec,
	)

	abreviated_name: cstring
	was_allocated: bool
	if len(file_stem) > max_file_name {
		abreviated_name = fmt.caprintf(
			"%s...%s%s",
			file_stem[:10],
			file_stem[len(file_stem) - 3:],
			file_extention,
		)
        was_allocated = true
	} else {
		abreviated_name = info.name
	}
	info.handle = fmt.caprintf("%s  %s  %s", info.size, abreviated_name, info.resolution)
    if was_allocated {
        delete(abreviated_name)
    }
	info.full_path = fmt.aprint(path)
	app.should_redraw = true
	return info
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
	keybidings["next_image"] = string_to_scancode(app.configs.keybidings.next_image)
	keybidings["prev_image"] = string_to_scancode(app.configs.keybidings.prev_image)
	keybidings["detailed_view"] = string_to_scancode(app.configs.keybidings.detailed_view)
	keybidings["toggle_dark_mode"] = string_to_scancode(app.configs.keybidings.toggle_dark_mode)
}

set_fullscreen :: proc(window: ^sdl.Window) {
	flags := sdl.GetWindowFlags(window)
	is_fullscreen := (flags & sdl.WINDOW_FULLSCREEN) != {}
	sdl.SetWindowFullscreen(window, !is_fullscreen)
}

next_image :: proc() {
	if len(app.images) > 0 {
		app.current_image += 1
		if app.current_image >= len(app.images) do app.current_image = 0
		app.should_redraw = true
		reset_zoom()
	}
}

previous_image :: proc() {
	if len(app.images) > 0 {
		app.current_image -= 1
		if app.current_image <= -1 do app.current_image = len(app.images) - 1
		app.should_redraw = true
		reset_zoom()
	}
}

toggle_dark_mode :: proc() {
	app.dark_mode = !app.dark_mode
	app.configs.ui.dark_mode = !app.configs.ui.dark_mode
	setup_colors()
	app.should_redraw = true
}
