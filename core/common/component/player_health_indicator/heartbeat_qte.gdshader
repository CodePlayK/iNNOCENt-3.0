shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 rect_size = vec2(128.0, 36.0);
uniform float scroll_px = 0.0;
uniform float energy : hint_range(0.0, 2.0) = 0.5;
uniform float flash : hint_range(-1.0, 1.0) = 0.0;
uniform float jagged : hint_range(0.0, 2.0) = 1.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform int w_count = 0;
uniform float w_x[8];
uniform float w_amp[8];
uniform float w_width[8];
uniform float w_cut[8];
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.94);
uniform vec4 panel_color : source_color = vec4(0.03, 0.04, 0.05, 0.42);
uniform vec4 hit_tint : source_color = vec4(0.55, 1.0, 0.78, 1.0);
uniform vec4 miss_tint : source_color = vec4(1.0, 0.32, 0.28, 1.0);

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453123);
}

float vertex_h(float i) {
	float n = hash(i * 3.17) * 2.0 - 1.0;
	n += (hash(i * 9.13 + 4.0) * 2.0 - 1.0) * 0.32;
	return n * 0.11 * jagged;
}

float qrs_shape(float u) {
	const vec2 k0 = vec2(-0.90, 0.00);
	const vec2 k1 = vec2(-0.22, 0.00);
	const vec2 k2 = vec2(-0.12, -0.28);
	const vec2 k3 = vec2(0.00, 1.00);
	const vec2 k4 = vec2(0.12, -0.46);
	const vec2 k5 = vec2(0.26, 0.00);
	const vec2 k6 = vec2(0.90, 0.00);
	vec2 a;
	vec2 b;
	if (u <= k0.x || u >= k6.x) {
		return 0.0;
	} else if (u < k1.x) {
		a = k0; b = k1;
	} else if (u < k2.x) {
		a = k1; b = k2;
	} else if (u < k3.x) {
		a = k2; b = k3;
	} else if (u < k4.x) {
		a = k3; b = k4;
	} else if (u < k5.x) {
		a = k4; b = k5;
	} else {
		a = k5; b = k6;
	}
	float t = (u - a.x) / max(b.x - a.x, 0.0001);
	return mix(a.y, b.y, t);
}

float small_y(float px, vec2 rs) {
	float cell_px = max(rs.x / 12.0, 6.0);
	float world = px + scroll_px;
	float g = world / cell_px;
	float i = floor(g);
	float f = fract(g);
	return mix(vertex_h(i), vertex_h(i + 1.0), f);
}

float qrs_y(float px, vec2 rs) {
	float y = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= w_count) {
			break;
		}
		float half_w = max(w_width[i], 1.0) * 0.5;
		float u = (px - w_x[i]) / half_w;
		if (u > w_cut[i] || u < -1.05) {
			continue;
		}
		y += qrs_shape(u) * w_amp[i];
	}
	return y;
}

float line_y(float px, vec2 rs) {
	float y = 0.5 + small_y(px, rs) - qrs_y(px, rs);
	return clamp(y, 0.08, 0.92);
}

float dist_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec2 uv = UV;
	vec2 rs = max(rect_size, vec2(8.0, 8.0));

	float edge_x = smoothstep(0.0, 0.04, uv.x) * smoothstep(1.0, 0.96, uv.x);
	float edge_y = smoothstep(0.0, 0.08, uv.y) * smoothstep(1.0, 0.92, uv.y);
	vec4 bg = panel_color;
	bg.a *= edge_x * edge_y;

	float dx = 1.0;
	vec2 p = uv * rs;
	float x0 = uv.x * rs.x;
	float x1 = x0 + dx;
	vec2 a = vec2(x0, line_y(x0, rs) * rs.y);
	vec2 b = vec2(x1, line_y(x1, rs) * rs.y);
	float d = dist_seg(p, a, b);

	float core = 1.0 - smoothstep(0.5, 1.3, d);
	float glow = 1.0 - smoothstep(1.0, 2.6, d);
	float line = max(core, glow * 0.3) * edge_x;

	vec3 lc = line_color.rgb;
	if (flash > 0.001) {
		lc = mix(lc, hit_tint.rgb, flash * 0.75);
	} else if (flash < -0.001) {
		lc = mix(lc, miss_tint.rgb, -flash * 0.75);
	}

	vec4 col = bg;
	col.rgb = mix(col.rgb, lc, line);
	col.a = max(col.a, line * (0.84 + energy * 0.16));
	COLOR = col;
}
