shader_type canvas_item;

// 颜色基础配置
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 0.45);
uniform vec4 line_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);         
uniform vec4 pulse_default_color : source_color = vec4(1.0, 0.6, 0.0, 1.0); 
uniform vec4 success_color : source_color = vec4(0.0, 1.0, 0.4, 1.0);      
uniform vec4 danger_color : source_color = vec4(1.0, 0.2, 0.2, 1.0);       

// 【手动指定大小】
uniform vec2 manual_rect_size = vec2(600.0, 200.0);
// 由脚本实时同步节点本身的物理像素大小，用于进行边界裁切计算
uniform vec2 actual_node_size = vec2(600.0, 200.0);

// 线条粗细与发光线
uniform float line_thickness : hint_range(0.005, 0.05) = 0.012;    
uniform float target_line_width : hint_range(0.002, 0.02) = 0.006; 

// 逻辑控制变量
uniform float target_x = 0.15;
uniform float pulse_center_x = 1.5;
uniform float pulse_width = 0.12;     
uniform int color_state = 0;          // 0: 移动中, 1: 成功, 2: 失败
uniform float animation_time = 0.0;   

// 单一高度控制参数
uniform float wave_height_scale : hint_range(0.0, 1.0) = 1.0;
// 用于失败时让大波浪丝滑衰减至直线的权重
uniform float fail_fade_weight = 1.0;

void fragment() {
	// ---- 【物理空间视口强切断拦截】 ----
	vec2 current_pixel = UV * actual_node_size;
	vec2 node_center_pixel = actual_node_size * 0.5;
	
	vec2 half_manual_size = manual_rect_size * 0.5;
	vec2 min_bound = node_center_pixel - half_manual_size;
	vec2 max_bound = node_center_pixel + half_manual_size;
	
	if (current_pixel.x < min_bound.x || current_pixel.x > max_bound.x || 
		current_pixel.y < min_bound.y || current_pixel.y > max_bound.y) {
		discard; // 废弃超出手动指定大小范围的全部节点物理像素
	}

	// 将落在虚拟画布内的物理像素，重新缩放映射回局部独立虚拟 local_uv (0.0 到 1.0)
	vec2 local_uv = (current_pixel - min_bound) / manual_rect_size;
	float aspect = manual_rect_size.x / manual_rect_size.y;
	vec4 final_color = bg_color; 

	// 1. 绘制纵向白色判断线
	float dist_to_target = abs(local_uv.x - target_x);
	float target_line = smoothstep(target_line_width + 0.002, target_line_width - 0.002, dist_to_target);
	float target_glow = smoothstep(target_line_width * 3.5, 0.0, dist_to_target) * 0.25;
	final_color.rgb = max(final_color.rgb, (vec4(1.0, 1.0, 1.0, 1.0) * (target_line + target_glow)).rgb);

	// 2. 汉宁窗约束标准单周期双波（心率大波浪线发生器）
	float base_wave = 0.5; 
	float dist_to_pulse = local_uv.x - pulse_center_x;
	float big_wave_shape = 0.0;
	
	if (abs(dist_to_pulse) < pulse_width) {
		float local_t = (dist_to_pulse + pulse_width) / (pulse_width * 2.0);
		float raw_wave = sin(local_t * 2.0 * 3.1415926);
		float hanning_window = 0.5 * (1.0 - cos(local_t * 2.0 * 3.1415926));
		
		// 100% 精确归一化
		float standardized_shape = (raw_wave * hanning_window) / 0.385;
		
		// 基于 local_uv 扣除粗细、抗锯齿软边及安全垫，锁死在局部画布边界边缘
		float absolute_max_amp = 0.5 - (line_thickness * 0.5) - 0.006 - 0.005; 
		float target_amp = absolute_max_amp * wave_height_scale;
		
		big_wave_shape = standardized_shape * target_amp * fail_fade_weight;
	}

	// 3. 【核心要求：40% 距离前完全隐藏遮罩】
	// 距离左侧 40% 即为 X = 0.40。我们要求心率波从右向左移动到 0.65 时开始淡出，到 0.40 时彻底隐形（可见度为0）
	float visibility_mask = smoothstep(0.40, 0.65, pulse_center_x);
	
	// 重构隐藏逻辑开关：移动(0)与失败(2)保持完全相同的隐藏进度（失败时在暗处悄悄缩回直线不闪烁），只有成功(1)才强制点亮展示
	float final_mask = (color_state == 1) ? 1.0 : visibility_mask;
	float final_wave_y = base_wave + (big_wave_shape * final_mask);

	// 4. 线条抗锯齿遮罩
	float dist_to_wave = abs(local_uv.y - final_wave_y);
	float line_mask = smoothstep(line_thickness, line_thickness - 0.006, dist_to_wave);

	// 5. 动态混合线条颜色
	vec4 current_pulse_color = pulse_default_color; 
	if (color_state == 1) current_pulse_color = success_color; 
	if (color_state == 2) current_pulse_color = danger_color;  
	
	float gauss = exp(-pow(dist_to_pulse / pulse_width, 2.0));
	float color_blend = gauss * final_mask;
	
	if (line_mask > 0.0) {
		vec4 computed_line = line_color;
		// 失败时，不依赖环境可见度遮罩，直接用绝对的高斯衰减对这一段流淌过去的红直线进行染色
		float active_blend = (color_state == 2) ? gauss : color_blend;
		if (active_blend > 0.01) {
			computed_line = mix(line_color, current_pulse_color, active_blend);
		}
		final_color.rgb = mix(final_color.rgb, computed_line.rgb, line_mask);
		final_color.a = max(final_color.a, line_mask * computed_line.a);
	}

	COLOR = final_color;
}
