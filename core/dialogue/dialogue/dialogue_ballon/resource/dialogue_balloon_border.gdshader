shader_type canvas_item;

// 对话气泡动态高亮边框
// 用于 ColorRect 背景，在原有底色上叠加脉冲发光边框

uniform vec4 border_color : source_color = vec4(1.0, 0.88, 0.45, 0.95);
uniform float border_width : hint_range(0.5, 6.0) = 2.0; // 像素近似
uniform float pulse_speed : hint_range(0.5, 8.0) = 2.8;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.4;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.1;
uniform float corner_softness : hint_range(0.0, 0.08) = 0.015;

void fragment() {
	vec4 base = COLOR; // ColorRect.color * modulate

	// UV 到边缘的距离（0=边，0.5=中心）
	float dx = min(UV.x, 1.0 - UV.x);
	float dy = min(UV.y, 1.0 - UV.y);
	float edge = min(dx, dy);

	// 近似像素宽度（ColorRect 的 TEXTURE_PIXEL_SIZE 通常有效）
	float px = max(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y);
	if (px <= 0.0) {
		px = 0.01;
	}

	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	float bw = border_width * px * (1.0 + pulse * pulse_amount);

	// 边框 mask
	float border = 1.0 - smoothstep(0.0, bw + corner_softness, edge);
	// 内侧微光
	float inner_glow = exp(-edge / (bw * 2.5 + 0.001)) * glow_strength * (0.55 + 0.45 * pulse);

	vec3 rgb = base.rgb;
	rgb = mix(rgb, border_color.rgb, border * border_color.a);
	rgb += border_color.rgb * inner_glow * 0.35 * border_color.a;

	float a = max(base.a, border * border_color.a * 0.9);
	COLOR = vec4(rgb, a);
}
