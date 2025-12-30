package main

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import sdl "vendor:sdl3"
import "vendor:sdl3/image"
import im "shared:imgui"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import im_sdlr "shared:imgui/imgui_impl_sdlrenderer3"

main :: proc() {
	using fmt

    app.base_path = sdl.GetBasePath()
	load_config_file()
    setup_bindings()
    init_app(&app)
    
    ok := sdl.Init({.VIDEO, .EVENTS})
	if !ok {
		println("Error while creating window: ", sdl.GetError())
	}

	app.window = sdl.CreateWindow("Image Viewer", 1280, 720, {.RESIZABLE, .HIGH_PIXEL_DENSITY})
	defer sdl.DestroyWindow(app.window)

	app.renderer = sdl.CreateRenderer(app.window, nil)
	sdl.SetRenderVSync(app.renderer, 1)

	if app.renderer == nil {
		println("Error while creating renderer: ", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(app.renderer)
	
    // load via cli, or if you drag an image to the executable
	if len(os.args) > 1 {
		initial_path := os.args[1]
		app.current_image = load_image(app.renderer, initial_path)
		get_file_info(initial_path)
	}else{
        app.img_info_text = fmt.aprintf("Drop an image in the app!") 
    }
    
    init_imgui(app.window,app.renderer)
    
    //main loop
	for running {
		free_all(context.temp_allocator)
		if app.current_image != nil {
			sdl.GetTextureSize(app.current_image, &img_original_size.x, &img_original_size.y)
		}
 
		handle_input(app.renderer, app.window)
 
        if app.should_redraw {		
            render_imgui(app.renderer)
            render(app.renderer, app.current_image, app.window)
		    app.should_redraw = false
		}
	}

    cleanup()
}

cleanup::proc(){
    //todo cleanup function to delete everything that is still lodaded at this point
    fmt.println("cleaning up")
    sdl.DestroyTexture(app.current_image)  
    sdl.DestroyRenderer(app.renderer)
    sdl.DestroyWindow(app.window)
    im_sdl.Shutdown()
    im_sdlr.Shutdown()
    im.DestroyContext()
}

init_imgui::proc(window:^sdl.Window,renderer:^sdl.Renderer){
    im.CHECKVERSION()
    im.CreateContext()
    io:= im.GetIO()
    io.IniFilename = nil
    load_font(renderer,io)
    io.ConfigFlags += {.NavEnableKeyboard,.NavEnableGamepad,.DockingEnable}
    im_sdl.InitForSDLRenderer(window,renderer)
    im_sdlr.Init(renderer)
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
	scale_w := f32(app.win_size.x) / img_original_size.x
	scale_h := f32(app.win_size.y) / img_original_size.y

	scale := min(scale_w, scale_h)
	scale *= app.zoom_level

	display_w := img_original_size.x * scale
	display_h := img_original_size.y * scale

	return {display_w, display_h}
}


load_config_file :: proc() {
	config_path := fmt.tprintf("%sconfig.json", app.base_path)

	data, ok := os.read_entire_file(config_path)
	
    if !ok {
        fmt.println("Error while loading config.json, using default config")
		app.configs = default_configs
        return
	}
	defer delete(data)

    json.unmarshal(data, &app.configs)
}
