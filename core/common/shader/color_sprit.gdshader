shader_type canvas_item;
uniform vec4 color:source_color;
uniform vec4 from_color:source_color;
uniform vec4 to_color:source_color;
uniform bool enable;
uniform bool colored;
uniform bool mix_modulate = true;
uniform float precision = 0.1;
varying flat vec4 modulate;
uniform float mix_modulate_strength: hint_range(-2.0, 3.0) = 1.0;
uniform vec4 original_0: source_color;
uniform vec4 original_1: source_color;
uniform vec4 original_2: source_color;
uniform vec4 original_3: source_color;
uniform vec4 original_4: source_color;
uniform vec4 replace_0: source_color;
uniform vec4 replace_1: source_color;
uniform vec4 replace_2: source_color;
uniform vec4 replace_3: source_color;
uniform vec4 replace_4: source_color;

vec4 swap_color(vec4 color1){
	vec4 original_colors[5] = vec4[5] (original_0, original_1, original_2, original_3, original_4);
	vec4 replace_colors[5] = vec4[5] (replace_0, replace_1, replace_2, replace_3, replace_4);
	for (int i = 0; i < 5; i ++) {
		if (distance(color1, original_colors[i]) <= precision){
		return replace_colors[i];
	}
	}
	if (distance(color1, from_color) <= precision){
		return to_color;
	}
	return color1;
}

void vertex() {
	modulate = COLOR;
}

void fragment() {
	if (enable){
	vec4 old_color=texture(TEXTURE,UV);
	
	if (colored){
		COLOR = color*mix_modulate_strength;
		COLOR.a=old_color.a*modulate.a;	
	}else{
		COLOR = swap_color(texture(TEXTURE, UV))*modulate;
	};
		
	if (mix_modulate){
		COLOR=COLOR*modulate*mix_modulate_strength;
		COLOR.a=old_color.a;
	};
	}
}
