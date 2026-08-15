package main

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:strings"
import im "shared:odin-imgui"
import im_sdl "shared:odin-imgui/imgui_impl_sdl3"
import im_sdlr "shared:odin-imgui/imgui_impl_sdlrenderer3"
import sdl "vendor:sdl3"
import sdli "vendor:sdl3/image"

tracking_alloc: mem.Tracking_Allocator

main :: proc() {

	mem.tracking_allocator_init(&tracking_alloc, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_alloc)

	app.base_path = get_config_dir()
	app.font_path, _ = filepath.join({app.base_path, "fonts"}, context.allocator)

	load_config_file()
	setup_bindings()
	app.dark_mode = app.configs.ui.dark_mode
	setup_colors()
	init_app(&app)

	ok := sdl.Init({.VIDEO, .EVENTS})
	if !ok {
		fmt.println("Error while creating window: ", sdl.GetError())
	}

	app.window = sdl.CreateWindow("Image Viewer", 1920, 1080, {.RESIZABLE, .HIGH_PIXEL_DENSITY})
	defer sdl.DestroyWindow(app.window)

	app.renderer = sdl.CreateRenderer(app.window, nil)
	sdl.SetRenderVSync(app.renderer, 1)

	if app.renderer == nil {
		fmt.println("Error while creating renderer: ", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(app.renderer)

	// load via cli, or if you drag an image to the executable
	if len(os.args) > 1 {
		app.show_keys = false
		initial_path := os.args[1]
		load_image(app.renderer, initial_path)
	}

	init_imgui(app.window, app.renderer)

	//main loop
	for running {
		free_all(context.temp_allocator)

		if len(app.images) > 0 {
			sdl.GetTextureSize(
				app.images[app.current_image].image,
				&app.images[app.current_image].size.x,
				&app.images[app.current_image].size.y,
			)
		}

		handle_input(app.renderer, app.window)

		if app.should_redraw {
			render_imgui(app.renderer)
			render(app.renderer, app.window)
			app.should_redraw = false
		}
	}
	save_config_file()
	quit()

	if len(tracking_alloc.allocation_map) > 0 {
		fmt.println("\n=== MEMORY LEAKS ===")
		for ptr, record in tracking_alloc.allocation_map {
			fmt.printf("Leak: %v bytes at %p\n", record.size, ptr)
			fmt.printf("  Location: %s:%d\n", record.location.file_path, record.location.line)
		}
	} else {
		fmt.println("No leaks!")
	}

	mem.tracking_allocator_destroy(&tracking_alloc)
}

quit :: proc() {
	free_config_varialbes()

	for img in app.images {
		if img.image != nil {
			sdl.DestroyTexture(img.image)
		}
		if img.info.ext != "" do delete(img.info.ext)
		if img.info.name != "" do delete(img.info.name)
		if img.info.size != "" do delete(img.info.size)
		if img.info.handle != "" do delete(img.info.handle)
		if img.info.created != "" do delete(img.info.created)
		if img.info.resolution != "" do delete(img.info.resolution)
		if img.info.modification != "" do delete(img.info.modification)
	}

	delete(app.images)
	delete(keybidings)

	// free paths
	delete(app.base_path)
	delete(app.font_path)
	delete(app.config_file_path)
	//
	sdl.DestroyRenderer(app.renderer)
	sdl.DestroyWindow(app.window)
	im_sdl.Shutdown()
	im_sdlr.Shutdown()
	im.DestroyContext()
}

init_imgui :: proc(window: ^sdl.Window, renderer: ^sdl.Renderer) {
	im.CHECKVERSION()
	im.CreateContext()
	io := im.GetIO()
	io.IniFilename = nil
	load_font(renderer, io)
	io.ConfigFlags += {.NavEnableKeyboard, .DockingEnable}
	im_sdl.InitForSDLRenderer(window, renderer)
	im_sdlr.Init(renderer)
}

load_image :: proc(renderer: ^sdl.Renderer, path: string) {
	//todo get a path as a folder and check every image inside it to load inside the img pool array

    file_stem := filepath.stem(filepath.base(path))
	for image in app.images {
		if string(image.info.name) == file_stem {
			set_current_image(image.index)
			return
		}
	}

	image: Image
	c_path := strings.clone_to_cstring(path, context.temp_allocator)

	surface := sdli.Load(c_path)

	if surface == nil {
		fmt.println("Error while loading image: ", sdl.GetError())
		return
	}
	defer sdl.DestroySurface(surface)

	texture := sdl.CreateTextureFromSurface(renderer, surface)
	if texture == nil {
		fmt.println("Error while creating texture: ", sdl.GetError())
		return
	}

	w, h: f32
	sdl.GetTextureSize(texture, &w, &h)

    image.size.x = w
    image.size.y = h

	image.image = texture
	image.index = len(app.images)
	image.info = get_file_info(path, &image)

	append(&app.images, image)
	app.current_image = len(app.images) - 1
}

calculate_display_size_with_zoom :: proc() -> Vec2 {

	if len(app.images) <= 0 do return {0, 0}
	scale_w := f32(app.win_size.x) / app.images[app.current_image].size.x
	scale_h := f32(app.win_size.y) / app.images[app.current_image].size.y

	scale := min(scale_w, scale_h)
	scale *= app.zoom_level

	display_w := app.images[app.current_image].size.x * scale
	display_h := app.images[app.current_image].size.y * scale

	return {display_w, display_h}
}

load_config_file :: proc() {
	app.config_file_path, _ = filepath.join({app.base_path, "config.json"}, context.allocator)
	data, err := os.read_entire_file(app.config_file_path, context.allocator)

	if err != nil {
		fmt.println("Error while loading config.json, using default config")
		app.configs = default_configs
		return
	}
	defer delete(data)

	json_err := json.unmarshal(data, &app.configs)

	if json_err != nil {
		fmt.println("Error parsing config.json: ", json_err)
		app.configs = default_configs
		return
	}

}

save_config_file :: proc() {
	path := app.config_file_path

	opt := json.Marshal_Options {
		pretty = true,
	}

	data, err := json.marshal(app.configs, opt, context.allocator)
	if err != nil {
		fmt.println("Error marshaling cofig file: ", err)
		return
	}
	defer delete(data)

	ok := os.write_entire_file(path, data)
	if ok != nil {
		fmt.println("Error saving config file: ", ok)
	}
}

get_config_dir :: proc() -> string {
	//plataform agnostic????? i hope so
	when ODIN_OS == .Windows {
		appdata := os.get_env("LOCALAPPDATA", context.allocator)
		if appdata != "" {
			path, _ := filepath.join({appdata, "img_viewer"}, context.allocator)
			return path
		}
		appdata = os.get_env("APPDATA", context.temp_allocator)
		if appdata != "" {
			path, _ := filepath.join({appdata, "img_viewer"}, context.allocator)
			return path
		}
		home := os.get_env("USERPROFILE", context.allocator)
		if home != "" {
			path, _ := filepath.join({home, ".config", "img_viewer"}, context.allocator)
			return path
		}
	} else when ODIN_OS == .Darwin {
		home := os.get_env("HOME", context.allocator)
		if home != "" {
			path, _ := filepath.join(
				{home, "Library", "Application Support", "img_viewer"},
				context.temp_allocator,
			)
			return path
		}
	} else {
		xdg := os.get_env("XDG_CONFIG_HOME", context.temp_allocator)
		if xdg != "" {
			path, _ := filepath.join({xdg, "img_viewer"}, context.allocator)
			return path
		}
		home := os.get_env("HOME", context.temp_allocator)
		if home != "" {
			path, _ := filepath.join({home, ".config", "img_viewer"}, context.allocator)
			return path
		}
	}
	return "./img_viewer"
}
