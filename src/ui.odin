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

test_color: [3]f32

color_flags: im.ColorEditFlags = {
	.NoAlpha,
	.NoPicker,
	.NoSmallPreview,
	.DisplayHex,
	.NoDragDrop,
	.NoTooltip,
}

draw_config_ui :: proc() {
	viewport := im.GetMainViewport()

	bkg_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.ui_bar_color_dark) : imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)

	text_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.text_color_dark) : imgui_hex_string_to_u32(app.configs.ui.text_color)

	im.PushStyleColor(.WindowBg, bkg_color)
	im.PushStyleColor(.Text, text_color)

	if im.Begin("Config Box", nil, {.NoTitleBar, .NoMove, .NoBringToFrontOnFocus}) {
		im.Checkbox("Dark Mode", &app.dark_mode)
		app.configs.ui.dark_mode = app.dark_mode
		im.InputFloat("Font_Size", &app.configs.ui.text_size, 1.0, format = "%.1f")
		// im.ColorEdit3("Background Color", &test_color, color_flags)
		im.End()
	}

	im.PopStyleColor(2)
}

draw_detail_view :: proc() {
	viewport := im.GetMainViewport()

	bkg_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.ui_bar_color_dark) : imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)

	text_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.text_color_dark) : imgui_hex_string_to_u32(app.configs.ui.text_color)

	im.PushStyleColor(.WindowBg, bkg_color)
	im.PushStyleColor(.Text, text_color)

	if im.Begin("Detailed View", nil, {.NoTitleBar, .NoMove, .NoBringToFrontOnFocus}) {
		im.End()
	}

	im.PopStyleColor(2)
}

draw_keybinds :: proc() {
	viewport := im.GetMainViewport()
	box_size: [2]f32 = {800, 600}

	bar_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.ui_bar_color_dark) : imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)

	text_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.text_color_dark) : imgui_hex_string_to_u32(app.configs.ui.text_color)

	im.PushStyleColor(.WindowBg, bar_color)
	im.PushStyleColor(.Text, text_color)
	im.SetNextWindowPos(
		{viewport.Size.x / 2 - (box_size.x / 2), viewport.Size.y / 2 - (box_size.y / 2)},
	)
	im.SetNextWindowSize(box_size)

	if im.Begin(
		"Keybindings",
		nil,
		{.NoTitleBar, .NoResize, .NoMove, .NoScrollbar, .NoBringToFrontOnFocus},
	) {
		centered_text("KEYBINDINGS: ")
		centered_text("Toggle Keybindings Menu: 'K'")
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

centered_text :: proc(text: cstring) {
	window_w := im.GetWindowWidth()
	text_w := im.CalcTextSize(text).x
	offset: f32 = (window_w - text_w) / 2

	if offset < 10.0 do offset = 10.0

	im.SetCursorPosX(offset)
	im.Text(text)
}

draw_bottom_ui :: proc() {
	viewport := im.GetMainViewport()
	bar_height: f32 = 100.0
	top_offset: f32 = bar_height / 2

	im.SetNextWindowPos({viewport.Pos.x, viewport.Size.y - top_offset})
	im.SetNextWindowSize({viewport.Size.x, bar_height})

	bar_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.ui_bar_color_dark) : imgui_hex_string_to_u32(app.configs.ui.ui_bar_color)

	text_color :=
		app.dark_mode ? imgui_hex_string_to_u32(app.configs.ui.text_color_dark) : imgui_hex_string_to_u32(app.configs.ui.text_color)

	im.PushStyleColor(.WindowBg, bar_color)
	im.PushStyleColor(.Text, text_color)

	if im.Begin(
		"BottomBar",
		nil,
		{.NoTitleBar, .NoResize, .NoMove, .NoScrollbar, .NoBringToFrontOnFocus},
	) {

		im.SetCursorPosY(15.0)

		if len(app.images) > 0 {
			im.TextUnformatted(
				strings.clone_to_cstring(
					app.images[app.current_image].info,
					context.temp_allocator,
				),
			)
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
	font_path, err := filepath.join({app.font_path, app.configs.ui.font})
	app.ui_font = im.FontAtlas_AddFontFromFileTTF(
		io.Fonts,
		strings.clone_to_cstring(font_path, context.temp_allocator),
		app.configs.ui.text_size,
	)
	if app.ui_font == nil {
		fmt.println("Failed to load font!")
	}
}
