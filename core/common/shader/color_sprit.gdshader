shader_type canvas_item;

uniform bool enable = true;
uniform float precision = 0.1;

// 可选：整图单色替换对（未命中 0~4 时再用）
uniform vec4 from_color : source_color =vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 to_color : source_color = vec4(1.0);

// 选择性替换表（最多 5 组）
uniform vec4 original_0 : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 original_1 : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 original_2 : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 original_3 : source_color =vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 original_4 : source_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 replace_0 : source_color;
uniform vec4 replace_1 : source_color;
uniform vec4 replace_2 : source_color;
uniform vec4 replace_3 : source_color;
uniform vec4 replace_4 : source_color;

// 替换后再叠加的目标色
uniform bool overlay_enable = false;
uniform vec4 overlay_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 0 = 不叠，1 = 完全按 overlay 方式混合
uniform float overlay_strength : hint_range(0.0, 1.0) = 0.5;
// 0 multiply  1 mix插值  2 soft 偏亮叠加
uniform int overlay_mode = 1;

uniform bool mix_modulate = true;
uniform float mix_modulate_strength : hint_range(0.0, 3.0) = 1.0;

varying flat vec4 modulate;

vec4 swap_color(vec4 c) {
	vec4 originals[5] = vec4[](original_0, original_1, original_2, original_3, original_4);
	vec4 replaces[5] = vec4[](replace_0, replace_1, replace_2, replace_3, replace_4);

	for (int i = 0; i < 5; i++) {
		if (distance(c.rgb, originals[i].rgb) <= precision) {
			return vec4(replaces[i].rgb, c.a);
		}
	}
	if (distance(c.rgb, from_color.rgb) <= precision) {
		return vec4(to_color.rgb, c.a);
	}
	return c;
}

vec4 apply_overlay(vec4 base) {
	if (!overlay_enable || overlay_strength <= 0.0) {
		return base;
	}

	vec3 result = base.rgb;
	if (overlay_mode == 0) {
		// 正片叠底
		result = base.rgb * overlay_color.rgb;
	} else if (overlay_mode == 2) {
		// 简易柔光：偏亮叠加
		result = 1.0 - (1.0 - base.rgb) * (1.0 - overlay_color.rgb);
	} else {
		// 线性混合
		result = mix(base.rgb, overlay_color.rgb, overlay_color.a);
	}

	result = mix(base.rgb, result, overlay_strength);
	return vec4(result, base.a);
}

void vertex() {
	modulate = COLOR;
}
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 col = tex;

	if (enable) {
		// 1) 选择性换色
		col = swap_color(tex);

		// 2) 在换色结果上叠加目标色
		col = apply_overlay(col);

		// 3) 节点 Modulate
		if (mix_modulate) {
			col.rgb *= modulate.rgb * mix_modulate_strength;
			col.a = tex.a * modulate.a;
		} else {
			col.a = tex.a * modulate.a;
		}
	} else {
		col = tex * modulate;
	}

	COLOR = col;
}
