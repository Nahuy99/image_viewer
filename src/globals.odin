package main

import sdl "vendor:sdl3"
import im "shared:imgui"

Vec2 :: [2]f32

img_original_size: Vec2

App::struct{
    window: ^sdl.Window,
    window_scale_factor: f32,
    renderer: ^sdl.Renderer,
    win_size: [2]i32,
    configs: App_Config,
    base_path: cstring,
    should_redraw: bool,
   
    ui_font: ^im.Font,

    img_info_text:string,
    
    zoom_level: f32,
    zoom_text:string,

    display_size: Vec2,
    current_image: ^sdl.Texture
}

app:App

init_app::proc(app: ^App){
    app.zoom_level = 1.0
    app.should_redraw = true
    app.base_path = sdl.GetBasePath()
}

App_Config :: struct {
    ui:         UI_config `json:"ui"`,
	keybidings: Keybidings_Config `json:"keybinds"`,
}

Keybidings_Config :: struct {
    fullscreen: string `json:"fullscreen"`,
    hide_ui: string `json:"hide_ui"`,
    quit: string `json:"quit"`,
    reset_view: string `json:"reset_view"`,
}

UI_config :: struct {
	bg_color:     string `json:"background"`,
	ui_bar_color: string `json:"ui_bar"`,
	text_color:   string `json:"text"`,
	text_size:    f32 `json:"text_size"`,
}

default_configs: App_Config = {
	ui = UI_config{
		bg_color = "FFFFEA",
		ui_bar_color = "BF5E5E",
		text_color ="FFFFEA",
		text_size = 26.0,
	},
    keybidings = Keybidings_Config{
        fullscreen = "F11"
    }
}
