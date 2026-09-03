shader_type canvas_item;

// 1. 特别注意：Render Mode 设为 unshaded（不受灯光直接控制）
render_mode unshaded;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, source_color;

void fragment() {
	// 正常采样并模糊屏幕已有的画面（此时画面里已经包含关卡原本的灯光了）
	COLOR = textureLod(screen_texture, SCREEN_UV, blur_amount);
}
