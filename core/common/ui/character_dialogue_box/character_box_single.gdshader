shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 100.0) = 16.0;

void fragment() {
    vec2 size = vec2(textureSize(TEXTURE, 0));
    vec2 uv = UV;
    vec2 pixel = uv * size;
    
    vec2 corner = min(pixel, size - pixel);
    float dist = length(max(vec2(corner_radius) - corner, vec2(0.0)));
    
    float alpha = 1.0 - smoothstep(corner_radius - 0.5, corner_radius + 0.5, dist);
    
    COLOR = texture(TEXTURE, uv);
    COLOR.a *= alpha;
}