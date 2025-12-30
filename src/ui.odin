package main

import "core:fmt"
import "core:strings"
import sdl "vendor:sdl3"
import im "shared:imgui"
import "core:strconv"


UI_HIDE_TIME :: 3.0
UI_SLIDE_SPEED :: 500.0

ui_is_visible: bool = true

hex_to_u32 :: proc(hex: u32) -> u32 {
    r := f32((hex >> 16) & 0xFF) / 255.0
    g := f32((hex >> 8) & 0xFF) / 255.0
    b := f32((hex >> 0)  & 0xFF) / 255.0
    a : f32 = 1.0 
    return im.ColorConvertFloat4ToU32({r, g, b, a})
}

hex_string_to_u32::proc(hex:string)->u32{
    val,ok:= strconv.parse_uint(hex,16)
    if !ok{
        return 0
    }

    result := u32(val) | 0xFF000000
    return result
}

imgui_hex_string_to_u32::proc(hex_string:string)-> u32{
    val,ok:= strconv.parse_uint(hex_string,16)
    hex := u32(val)
    
    r := f32((hex >> 16) & 0xFF) / 255.0
    g := f32((hex >> 8)  & 0xFF) / 255.0
    b := f32((hex >> 0)  & 0xFF) / 255.0
    
    final_color := im.ColorConvertFloat4ToU32({r, g, b, 1.0})
    return final_color
}

draw_top_ui::proc(){
    viewport := im.GetMainViewport()
    bar_height: f32 = 100.0
    top_offset: f32 = bar_height/2

    button_size:f32 = 15
    
    im.SetNextWindowPos({viewport.Pos.x,viewport.Pos.y - top_offset})
    im.SetNextWindowSize({viewport.Size.x, bar_height})

    bar_color := imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)  
    im.PushStyleColor(.WindowBg, bar_color)

    im.PushStyleVar(.WindowRounding, 20.0)
    im.PushStyleVar(.WindowBorderSize, 0.0)

    if im.Begin("TopBar", nil, {.NoTitleBar,.NoResize,.NoMove,.NoScrollbar,.NoBringToFrontOnFocus}) {
        im.SetCursorPosX(15.0) 
        im.SetCursorPosY(top_offset + 20.0) 

        im.PushStyleVar(.FrameRounding, 10.0) 
       
        im.PushStyleColor(.Button,hex_to_u32(0x403434))
        if im.Button("##close", {button_size,button_size}) {
            running = false
        }
        im.PopStyleColor()
        
        im.SameLine()
        
        im.PushStyleColor(.Button,hex_to_u32(0x65BF5E))
        if im.Button("##mini", {button_size,button_size}) {
           sdl.MinimizeWindow(app.window)  
        }
        im.PopStyleColor()
        
        im.SameLine()
        
        im.PushStyleColor(.Button,hex_to_u32(0x5EBF9A))
        if im.Button("##max", {button_size,button_size}) {
           set_fullscreen(app.window)  
        }
        im.PopStyleColor()
        
        im.PopStyleVar() 
        
        im.End()
    }
    im.PopStyleVar(2)
    im.PopStyleColor(1)

}

draw_bottom_ui::proc(){
    viewport := im.GetMainViewport()
    bar_height: f32 = 100.0
    top_offset: f32 = bar_height/2

    im.SetNextWindowPos({viewport.Pos.x,viewport.Size.y - top_offset})
    im.SetNextWindowSize({viewport.Size.x, bar_height})

    
    bar_color := imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)  
    im.PushStyleColor(.WindowBg, bar_color)

    im.PushStyleVar(.WindowRounding, 20.0)
    im.PushStyleVar(.WindowBorderSize, 0.0)

    if im.Begin("BottomBar", nil, {.NoTitleBar,.NoResize,.NoMove,.NoScrollbar,.NoBringToFrontOnFocus}) {
        
        im.SetCursorPosY(15.0) 
        
        text_color:= imgui_hex_string_to_u32(app.configs.ui.text_color) 
        im.PushStyleColor(.Text,text_color)
        im.TextUnformatted(strings.clone_to_cstring(app.img_info_text,context.temp_allocator))
        
        zoom_str := fmt.tprintf("%.0f%%", app.zoom_level * 100) 
        zoom_width := im.CalcTextSize(strings.clone_to_cstring(zoom_str,context.temp_allocator)).x
        right_margin: f32 = 15.0

        right_pos := im.GetWindowWidth() - zoom_width - right_margin
        
        im.SameLine(right_pos)
        im.TextUnformatted(strings.clone_to_cstring(zoom_str,context.temp_allocator))
        im.PopStyleColor() 
        im.End()
    } 
    im.PopStyleVar(2)
    im.PopStyleColor(1)
}

load_font :: proc(renderer: ^sdl.Renderer,io:^im.IO) {
	using fmt
	font_path := tprintf("%sassets/fonts/JetBrainsMonoNerdFont-Bold.ttf", app.base_path)

    app.ui_font = im.FontAtlas_AddFontFromFileTTF(io.Fonts,strings.clone_to_cstring(font_path,context.temp_allocator),app.configs.ui.text_size)

    if app.ui_font == nil {
        fmt.println("Failed to load font!")
    }
    
    im.FontAtlas_Build(io.Fonts)
}

