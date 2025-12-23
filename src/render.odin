package main

import "vendor:sdl3/ttf"
import sdl "vendor:sdl3"
display_size : Vec2

ui_elements::struct{
    w,h: f32,
    x,y:f32,
    r,g,b: u8,
    a:u8
}

ui_bottom_bar:ui_elements = {h= 50,r = 85,g = 85,b= 85,a = 255}
ui_bottom_bar_text:ui_elements = {r=226, g=226 ,b=209, a= 255}

render :: proc(renderer:^sdl.Renderer,texture:^sdl.Texture) {
	sdl.SetRenderDrawColor(renderer, 255, 255, 234, 25)
	sdl.RenderClear(renderer)

	display_size = calculate_display_size_with_zoom()

    base_x := (f32(win_size.x) - display_size.x) / 2   
    base_y := (f32(win_size.y) - display_size.y) / 2
	
    destination_rec := sdl.FRect {
		x = base_x + pan_offset.x,
		y = base_y + pan_offset.y,
		w = display_size.x,
		h = display_size.y,
	}

	sdl.RenderTexture(renderer, texture, nil, &destination_rec)
    
    ui_rec:= sdl.FRect{
        x = 0,
        y = f32(win_size.y) - ui_bottom_bar.h,
        w = f32(win_size.x),
        h =ui_bottom_bar.h,
    }

    sdl.SetRenderDrawColor(renderer,ui_bottom_bar.r,ui_bottom_bar.g,ui_bottom_bar.b,ui_bottom_bar.a)
    sdl.RenderFillRect(renderer,&ui_rec)

    ttf.DrawRendererText(left_image_info_text,10,f32(win_size.y) - (ui_bottom_bar.h -10 ))
    
    zoom_text_w: i32
    ttf.GetTextSize(right_image_info_text,&zoom_text_w,nil)
    ttf.DrawRendererText(right_image_info_text,f32(win_size.x)-f32(zoom_text_w) - 10,f32(win_size.y) - (ui_bottom_bar.h - 10))

	sdl.RenderPresent(renderer)
}
