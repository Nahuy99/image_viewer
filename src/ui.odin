package main

import "core:fmt"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import im "shared:odin-imgui"
import sdl "vendor:sdl3"


UI_HIDE_TIME :: 3.0
UI_SLIDE_SPEED :: 500.0

ui_is_visible: bool = true

hex_to_u32 :: proc(hex: u32) -> u32 {
	r := f32((hex >> 16) & 0xFF) / 255.0
	g := f32((hex >> 8) & 0xFF) / 255.0
	b := f32((hex >> 0) & 0xFF) / 255.0
	a: f32 = 1.0
	return im.ColorConvertFloat4ToU32({r, g, b, a})
}

hex_string_to_u32 :: proc(hex: string) -> u32 {
	val, ok := strconv.parse_uint(hex, 16)
	if !ok {
		return 0
	}
	result := u32(val) | 0xFF000000
	return result
}

imgui_hex_string_to_u32 :: proc(hex_string: string) -> u32 {
	val, ok := strconv.parse_uint(hex_string, 16)
	hex := u32(val)

	r := f32((hex >> 16) & 0xFF) / 255.0
	g := f32((hex >> 8) & 0xFF) / 255.0
	b := f32((hex >> 0) & 0xFF) / 255.0

	final_color := im.ColorConvertFloat4ToU32({r, g, b, 1.0})
	return final_color
}

draw_config_ui :: proc() {
	viewport := im.GetMainViewport()
	side_ui := im.FindWindowByName("SideBar")
	side_ui_w: f32
	if side_ui != nil do side_ui_w = side_ui.Size.x

	size: Vec2 = {340, 50}
	pos: Vec2 = app.show_side_ui ? {side_ui_w + 30, 30} : {30, 30}

	drop_shadow({10, 10}, size, pos, "Drop Shadow Config")
	setup_window(app.configs.bar_color, app.configs.text_color, pos, size)

	if im.Begin("Config Box", nil, {.NoTitleBar, .NoMove, .NoResize}) {
		im.SetNextItemWidth(150)
		im.InputFloat("Font_Size", &app.configs.ui.text_size, 1.0, format = "%.1f")
		im.End()
	}
	im.PopStyleColor(2)
}

draw_detail_view :: proc() {
	viewport := im.GetMainViewport()
	size: Vec2 = {600, 200}
	side_ui := im.FindWindowByName("SideBar")
	side_ui_w: f32
	if side_ui != nil do side_ui_w = side_ui.Size.x

	if len(app.images) > 0 {
		name_size := im.CalcTextSize(app.images[app.current_image].info.name).x + 30
		last_mod_size := im.CalcTextSize(app.images[app.current_image].info.modification).x + 30
		if last_mod_size > name_size do size.x = last_mod_size
		else do size.x = name_size
	}

	offset: Vec2 = {app.show_side_ui ? side_ui_w + 30 : 30, app.show_config ? 130 : 30}
	pos := viewport.Pos + offset

	drop_shadow({20, 20}, size, pos, "Detail Drop Shadow")

	setup_window(app.configs.bar_color, app.configs.text_color, pos, size)

	if im.Begin(
		"Detailed View",
		nil,
		{.NoTitleBar, .NoMove, .NoResize, .NoScrollbar, .NoScrollWithMouse},
	) {
		if len(app.images) > 0 {
			im.TextUnformatted(app.images[app.current_image].info.name)
			im.TextUnformatted(app.images[app.current_image].info.ext)
			im.TextUnformatted(app.images[app.current_image].info.size)
			im.TextUnformatted(app.images[app.current_image].info.resolution)
			im.TextUnformatted(app.images[app.current_image].info.created)
			im.TextUnformatted(app.images[app.current_image].info.modification)
		} else {
			im.TextUnformatted("Drop an image to see the details")
		}
		im.End()
	}

	im.PopStyleColor(2)
}

draw_keybinds :: proc() {
	viewport := im.GetMainViewport()
	size: Vec2 = {800, 600}
	pos: Vec2 = {viewport.Size.x / 2 - (size.x / 2), viewport.Size.y / 2 - (size.y / 2)}

	drop_shadow({20, 20}, size, pos, "Keybinds Drop Shadow")
	setup_window(app.configs.bar_color, app.configs.text_color, pos, size)

	if im.Begin("Keybindings", nil, {.NoTitleBar, .NoResize, .NoMove, .NoScrollbar}) {
		centered_text("KEYBINDINGS: ")
		centered_text("Toggle Keybindings Menu: 'K'")
		centered_text("Toggle Side Bar : 'B'")
		centered_text("Toggle Dark Mode: 'G'")
		centered_text("Toggle Fullscreen : 'F'")
		centered_text("Toggle Detailed View : 'D'")
		centered_text("Toggle Config Box : 'C'")
		centered_text("Previuous Image : 'P'")
		centered_text("Next Image : 'N'")
		im.End()
	}

	im.PopStyleColor(2)
}

draw_side_ui :: proc() {
	viewport := im.GetMainViewport()
	pos: Vec2 = {20, 30}
	size: Vec2

	bottom_bar := im.FindWindowByName("BottomBar")
	if bottom_bar != nil {
		bottom_bar_height := bottom_bar.Size.y
		size = {600, viewport.Size.y - bottom_bar_height}
	} else do size = {600, viewport.Size.y}

	drop_shadow({20, 15}, size, pos, "Drop Shadow Side Ui")

	setup_window(app.configs.bar_color, app.configs.text_color, pos, size)
	if im.Begin("SideBar", nil, {.NoTitleBar, .NoResize, .NoMove, .NoScrollbar}) {
		im.PushStyleColor(.ChildBg, app.configs.accent)
		if im.BeginChild("Currently Open", {0, 0}, {.Borders}) {
			centered_text("currently opened images")
			if len(app.images) > 0 {
				im.PushStyleColor(.Button, app.configs.button_color)
				im.PushStyleColor(.ButtonHovered, app.configs.bar_color)
				im.PushStyleColor(.ButtonActive, app.configs.button_active_color)
				for image in app.images {
					is_selected := image.index == app.current_image
					if is_selected {
						im.PushStyleColor(.Button, app.configs.image_selected)
					}
					if centered_button(image.info.name) {
						set_current_image(image.index)
						reset_zoom()
					}
					if is_selected {
                        im.PopStyleColor(1)
					}
				}
				im.PopStyleColor(3)
			}
		}
		im.EndChild()
		im.PopStyleColor()

		im.End()
	}
	im.PopStyleColor(2)
}

draw_bottom_ui :: proc() {
	viewport := im.GetMainViewport()
	bar_height: f32 = 100.0
	top_offset: f32 = bar_height / 2
	pos: Vec2 = {viewport.Pos.x, viewport.Size.y - top_offset}
	size: Vec2 = {viewport.Size.x, bar_height}

	setup_window(app.configs.bar_color, app.configs.text_color, pos, size)

	if im.Begin("BottomBar", nil, {.NoTitleBar, .NoResize, .NoMove, .NoScrollbar}) {

		im.SetCursorPosY(15.0)

		if len(app.images) > 0 {
			im.TextUnformatted(app.images[app.current_image].info.handle)
		} else {
			im.TextUnformatted("DROP IMAGE ON THE APP")
		}

		zoom_str := fmt.tprintf("%.0f%%", app.zoom_level * 100)
		zoom_width := im.CalcTextSize(strings.clone_to_cstring(zoom_str, context.temp_allocator)).x
		right_margin: f32 = 15.0

		right_pos := im.GetWindowWidth() - zoom_width - right_margin

		im.SameLine(right_pos)
		im.TextUnformatted(strings.clone_to_cstring(zoom_str, context.temp_allocator))
		im.End()
	}
	im.PopStyleColor(2)
}

load_font :: proc(renderer: ^sdl.Renderer, io: ^im.IO) {
	font_path, err := filepath.join({app.font_path, app.configs.ui.font}, context.temp_allocator)
	app.ui_font = im.FontAtlas_AddFontFromFileTTF(
		io.Fonts,
		strings.clone_to_cstring(font_path, context.temp_allocator),
		app.configs.ui.text_size,
	)
	if app.ui_font == nil {
		fmt.println("Failed to load font!")
	}
}

set_current_image :: proc(index: int) {
	app.current_image = index
}

setup_window :: proc(color, text_color: u32, pos, size: Vec2) {
	im.PushStyleColor(.WindowBg, color)
	im.PushStyleColor(.Text, text_color)
	im.SetNextWindowPos(pos)
	im.SetNextWindowSize(size)
}

drop_shadow :: proc(offset, box_size, box_pos: Vec2, name: cstring) {
	shadow_pos := box_pos + offset

	im.SetNextWindowPos(shadow_pos)
	im.SetNextWindowSize(box_size)
	im.PushStyleColor(.WindowBg, app.configs.shadow_color)
	if im.Begin(
		name,
		nil,
		{.NoTitleBar, .NoResize, .NoMove, .NoScrollbar, .NoBringToFrontOnFocus, .NoNavInputs},
	) {
		im.End()
	}
	im.PopStyleColor()
}

centered_text :: proc(text: cstring) {
	window_w := im.GetWindowWidth()
	text_w := im.CalcTextSize(text).x
	offset: f32 = (window_w - text_w) / 2

	if offset < 10.0 do offset = 10.0

	im.SetCursorPosX(offset)
	im.Text(text)
}

centered_button :: proc(label: cstring, offset: f32 = 0) -> bool {
	style := im.GetStyle()
	text_width := im.CalcTextSize(label).x
	button_width := text_width + style.FramePadding.x * 2
	avail_width := im.GetContentRegionAvail().x
	im.SetCursorPosX(max(0, (avail_width - button_width) * 0.5 + offset))
	return im.Button(label)
}
