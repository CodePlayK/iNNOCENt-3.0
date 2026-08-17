shader_type canvas_item;

// ====================== 动态目标驱动的轮廓背光 ======================

uniform bool enable_rim = true;

uniform float rim_width_px : hint_range(0.5, 20.0, 0.1) = 4.0;
uniform float rim_intensity : hint_range(0.0, 10.0, 0.01) = 5;
uniform float rim_softness : hint_range(0.1, 3.0, 0.01) = 1.2;
uniform int sample_count : hint_range(2, 8) = 5;

uniform vec2 light_dir = vec2(1.0, 0.0);
uniform float distance_strength : hint_range(0.0, 3.0, 0.01) = 1.0;

void fragment() {
	// COLOR 进入时已经包含了 Sprite 的 modulate
	vec4 modulate = COLOR;
	vec4 tex = texture(TEXTURE, UV);
	
	vec3 result = tex.rgb;
	float final_alpha = tex.a;
	
	// 只有在条件满足时才计算边缘光
	if (enable_rim && tex.a > 0.01 && distance_strength > 0.001 && modulate.a > 0.001) {
		vec2 ps = 1.0 / vec2(textureSize(TEXTURE, 0));
		vec2 dir = normalize(light_dir);
		
		float accum = 0.0;
		for (int i = 1; i <= sample_count; i++) {
			float t = float(i) / float(sample_count);
			vec2 offset = dir * t * rim_width_px * ps * rim_softness;
			accum += (1.0 - texture(TEXTURE, UV + offset).a);
		}
		
		float rim = accum / float(sample_count);
		rim = clamp(rim, 0.0, 1.0);
		rim = pow(rim, 1.2);
		
		// 使用自带的 modulate 计算衰减
		float modulate_luma = dot(modulate.rgb, vec3(0.299, 0.587, 0.114));
		float modulate_factor = modulate.a * clamp(modulate_luma, 0.15, 1.0);
		
		rim *= rim_intensity * distance_strength * modulate_factor;
		
		result = tex.rgb * (1.0 + rim);
	}
	
	// 最后统一乘上 modulate
	COLOR = vec4(result, final_alpha) * modulate;
}