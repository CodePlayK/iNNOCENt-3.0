shader_type canvas_item;

void fragment() {
    // textur(TEXTURE, UV) 获取粒子原本的纹理和粒子材质里的颜色
    // 故意不乘以系统的 MODULATE
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = tex_color * COLOR; 
}
