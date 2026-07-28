shader_type canvas_item;
uniform vec2 player_position;
uniform float circle_radius = 432.41;
uniform float inner_circle_radius_scale = -0.045;
uniform float strength = 0.815;
varying flat vec4 modulate;
void vertex() {
	modulate = COLOR;
}

void fragment( )
{	
    vec2 current_pixel = SCREEN_UV/SCREEN_PIXEL_SIZE;
    // 计算当前像素到圆心的距离
    float distance_to_center = distance(current_pixel, player_position/SCREEN_PIXEL_SIZE);
	if (COLOR.a != 0.0 && distance_to_center < circle_radius && distance_to_center>inner_circle_radius_scale*circle_radius) {
		COLOR.a =.2+COLOR.a/circle_radius*(distance_to_center-inner_circle_radius_scale*circle_radius)*strength;
    } else if(COLOR.a != 0.0 && distance_to_center<inner_circle_radius_scale*circle_radius){
		COLOR.a=0.2;
    }
}