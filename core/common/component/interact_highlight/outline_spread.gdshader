shader_type canvas_item;
render_mode unshaded;

uniform float progress = 0.0; 
uniform vec2 view_size;
uniform vec2 sprite_center_screen;
uniform vec2 sprite_size_screen;
uniform vec2 dot_center_screen;

uniform vec4 glow_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float dot_size = 8.0;            
uniform float breathe_amplitude = 0.2;
uniform float breathe_speed = 2.5;
uniform float border_thickness = 1.2;     
uniform float glitch_speed = 15.0;       
uniform float glitch_amplitude = 2.0;   

float hash_rand(float n) { 
    return fract(sin(n) * 43758.5453123); 
}

float get_glitch_noise(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash_rand(i), hash_rand(i + 1.0), u);
}

void fragment() {
    vec2 pixel_pos = SCREEN_UV * view_size;
    vec2 current_center = mix(dot_center_screen, sprite_center_screen, clamp(progress, 0.0, 1.0));
    vec2 half_size = (sprite_size_screen * 0.5) * max(progress, 0.0);

    float breathe = 1.0 + breathe_amplitude * sin(TIME * breathe_speed);
    float current_dot_radius = dot_size * 0.5 * breathe;

    vec2 relative_pos = pixel_pos - current_center;
    float current_corner_radius = mix(current_dot_radius, 1.0, clamp(progress, 0.0, 1.0));
    vec2 current_box_extents = max(half_size - vec2(current_corner_radius), vec2(0.0));

    vec2 d = abs(relative_pos) - current_box_extents;
    float sdf_dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - current_corner_radius;

    if (progress > 0.01) {
        float angle = atan(relative_pos.y, relative_pos.x);
        float noise1 = get_glitch_noise(angle * 3.0 + TIME * glitch_speed);
        float noise2 = get_glitch_noise(angle * 8.0 - TIME * glitch_speed * 1.5);
        float combined_noise = (noise1 * 0.6 + noise2 * 0.4) - 0.5; 
        sdf_dist += combined_noise * glitch_amplitude * clamp(progress, 0.0, 1.0);
    }

    float border_line = smoothstep(border_thickness, 0.0, abs(sdf_dist + border_thickness * 0.5));
    border_line *= step(sdf_dist, 0.0); 

    float dot_glow = smoothstep(current_dot_radius, 0.0, length(pixel_pos - dot_center_screen)) * 0.8;
    float final_alpha = mix(dot_glow, border_line, clamp(progress, 0.0, 1.0));
    
    if (progress > 1.0) {
        final_alpha = border_line;
    }

    COLOR = vec4(glow_color.rgb, final_alpha * glow_color.a);
}
