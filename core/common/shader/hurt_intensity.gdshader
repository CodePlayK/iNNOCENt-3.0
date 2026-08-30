shader_type canvas_item;

// 1. 全局控制：0.0 为健康，1.0 为极度垂危
uniform float hurt_intensity : hint_range(0.0, 1.0) = 0.0;

// 2. 控制黑色与血色的比例 (值越大，最外圈黑色越粗)
uniform float black_border_ratio : hint_range(0.0, 1.0) = 0.35;

// 3. 【参数名保持一致】全局心跳频率倍率
// 默认 1.0 为标准速度。值越大心跳越快，值越小心跳越慢。
uniform float pulse_frequency : hint_range(0.1, 5.0) = 1.0;

// 4. 颜色配置
uniform vec4 blood_color : source_color = vec4(0.5, 0.0, 0.0, 1.0); // 血色
uniform vec4 border_black : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 最外圈的黑色

// 5. 屏幕纹理
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // 获取基础画面和 UV
    vec4 scene_color = texture(screen_texture, SCREEN_UV);
    vec2 uv = SCREEN_UV;

    // --- 【核心优化：多相位无跳变混合算法】 ---
    // 1. 设定 4 个覆盖 0.1 到 5.0 范围的恒定速度基础齿轮（其速度是常量死代码，永远不会跳变）
    float f1 = 0.5;
    float f2 = 1.0;
    float f3 = 2.0;
    float f4 = 4.0;

    // 2. 计算 4 个基准时钟在当前 TIME 下的标准低心率(4.0)和高心率(12.0)波形
    float p_slow1 = sin(TIME * 4.0 * f1) * 0.5 + 0.5;
    float p_slow2 = sin(TIME * 4.0 * f2) * 0.5 + 0.5;
    float p_slow3 = sin(TIME * 4.0 * f3) * 0.5 + 0.5;
    float p_slow4 = sin(TIME * 4.0 * f4) * 0.5 + 0.5;

    float p_fast1 = sin(TIME * 12.0 * f1) * 0.5 + 0.5;
    float p_fast2 = sin(TIME * 12.0 * f2) * 0.5 + 0.5;
    float p_fast3 = sin(TIME * 12.0 * f3) * 0.5 + 0.5;
    float p_fast4 = sin(TIME * 12.0 * f4) * 0.5 + 0.5;

    // 3. 根据输入的 pulse_frequency 动态计算 4 个恒定齿轮的混合权重 (区间平滑过渡)
    float w1 = smoothstep(f2, f1, pulse_frequency);
    float w2 = smoothstep(f1, f2, pulse_frequency) * (1.0 - smoothstep(f2, f3, pulse_frequency));
    float w3 = smoothstep(f2, f3, pulse_frequency) * (1.0 - smoothstep(f3, f4, pulse_frequency));
    float w4 = smoothstep(f3, f4, pulse_frequency);
    
    // 归一化权重分配
    float w_sum = w1 + w2 + w3 + w4;
    w1 /= w_sum; w2 /= w_sum; w3 /= w_sum; w4 /= w_sum;

    // 4. 重构出无缝过渡的当前低心率与高心率波形
    float pulse_slow = (p_slow1 * w1) + (p_slow2 * w2) + (p_slow3 * w3) + (p_slow4 * w4);
    float pulse_fast = (p_fast1 * w1) + (p_fast2 * w2) + (p_fast3 * w3) + (p_fast4 * w4);
    
    // --- 100% 保留你原汁原味的心跳混合表现 ---
    // 根据受伤程度，平滑混合快慢两种心跳波形
    float pulse = mix(pulse_slow, pulse_fast, hurt_intensity);
    
    // 带有心跳起伏的动态受伤强弱值（心跳幅度随受伤加重而加大）
    float dynamic_intensity = hurt_intensity + (pulse * hurt_intensity * 0.25);
    dynamic_intensity = clamp(dynamic_intensity, 0.0, 1.0);

    // 计算 UV 到屏幕中心的距离平方
    vec2 center_dist = uv - vec2(0.5);
    float dist_squared = dot(center_dist, center_dist); 

    // --- 第一层：中央到血色的过渡 ---
    float blood_radius = 0.85 - (dynamic_intensity * 0.55); 
    float blood_softness = 0.45;
    float blood_mask = smoothstep(blood_radius - blood_softness, blood_radius, dist_squared);
    blood_mask *= dynamic_intensity;

    // --- 第二层：最外圈的黑色过渡 ---
    float black_radius = blood_radius + (1.0 - black_border_ratio) * 0.4;
    float black_softness = 0.3;
    float black_mask = smoothstep(black_radius - black_softness, black_radius, dist_squared);
    black_mask *= dynamic_intensity;

    // --- 颜色混合输出 ---
    // 画面基础微调
    vec4 tinted_scene = mix(scene_color, vec4(0.2, 0.0, 0.0, 1.0), hurt_intensity * 0.1);

    // 混合血色
    vec3 final_color = mix(tinted_scene.rgb, blood_color.rgb, blood_mask * 0.85);
    
    // 混合最外圈黑色
    final_color = mix(final_color, border_black.rgb, black_mask * 0.95);

    COLOR = vec4(final_color, 1.0);
}
