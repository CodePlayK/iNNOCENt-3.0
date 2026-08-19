shader_type canvas_item;

// ====================== 动态目标驱动的轮廓背光 ======================
// 已对所有方向的平直边缘做越界透明处理

uniform bool enable_rim = true;

uniform float rim_width_px : hint_range(0.5, 20.0, 0.1) = 4.0;
uniform float rim_intensity : hint_range(0.0, 10.0, 0.01) = 5.0;
uniform float rim_softness : hint_range(0.1, 3.0, 0.01) = 1.2;
uniform int sample_count : hint_range(2, 8) = 5;

uniform vec2 light_dir = vec2(1.0, 0.0);
uniform float distance_strength : hint_range(0.0, 10.0, 0.1) = 1.0;

void fragment() {
	vec4 modulate = COLOR;
	vec4 tex = texture(TEXTURE, UV);

	vec3 result = tex.rgb;
	float final_alpha = tex.a;

	if (enable_rim && tex.a > 0.01 && distance_strength > 0.001 && modulate.a > 0.001) {
		vec2 ps = 1.0 / vec2(textureSize(TEXTURE, 0));
		vec2 dir = normalize(light_dir);

		float rim = 0.0;

		// ========== 1. 软采样（沿光照方向） ==========
		float accum = 0.0;
		for (int i = 1; i <= sample_count; i++) {
			float t = float(i) / float(sample_count);
			vec2 sample_uv = UV + dir * t * rim_width_px * ps * rim_softness;

			float a = 0.0;
			// 关键：任何方向只要越界就视为透明
			if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 &&
				sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
				a = texture(TEXTURE, sample_uv).a;
			}
			accum += (1.0 - a);
		}
		float soft_rim = accum / float(sample_count);

		// ========== 2. 锐利差值检测（对平直边特别有效） ==========
		vec2 sharp_uv = UV + dir * rim_width_px * ps;
		float sharp_a = 0.0;
		if (sharp_uv.x >= 0.0 && sharp_uv.x <= 1.0 &&
			sharp_uv.y >= 0.0 && sharp_uv.y <= 1.0) {
			sharp_a = texture(TEXTURE, sharp_uv).a;
		}
		float sharp_rim = smoothstep(0.0, 0.9, tex.a - sharp_a);

		// ========== 3. 近距离检测 ==========
		vec2 near_uv = UV + dir * (rim_width_px * 0.4) * ps;
		float near_a = 0.0;
		if (near_uv.x >= 0.0 && near_uv.x <= 1.0 &&
			near_uv.y >= 0.0 && near_uv.y <= 1.0) {
			near_a = texture(TEXTURE, near_uv).a;
		}
		float near_rim = smoothstep(0.0, 0.75, tex.a - near_a);

		// 取最强的信号
		rim = max(soft_rim, max(sharp_rim, near_rim));
		rim = clamp(rim, 0.0, 1.0);
		rim = pow(rim, 1.05);

		// modulate 影响
		float modulate_luma = dot(modulate.rgb, vec3(0.299, 0.587, 0.114));
		float modulate_factor = modulate.a * clamp(modulate_luma, 0.15, 1.0);

		rim *= rim_intensity * distance_strength * modulate_factor;

		result = tex.rgb * (1.0 + rim);
	}

	COLOR = vec4(result, final_alpha) * modulate;
}