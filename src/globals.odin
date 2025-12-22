package main

Vec2 :: [2]f32

win_size: [2]i32
img_original_size: Vec2
window_scale_factor: f32

zoom_level: f32 = 1.0
pan_offset: Vec2
is_panning: bool
last_mouse_pos: Vec2
