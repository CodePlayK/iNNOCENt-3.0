shader_type canvas_item;

// 从 GDScript 传入的 ColorRect 实际像素尺寸
uniform vec2 rect_size = vec2(100.0, 100.0);

// 每根黑条的像素宽度
uniform float bar_width_pixels = 20.0;
// 每个格子的大致像素高度
uniform float grid_height_pixels = 20.0;

// 动画总进度：0.0 到 1.0
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// 【核心新增】：随机种子，每次动画传入不同值，彻底打乱黑条位置
uniform float seed = 0.0;

// 【长度随机度】与【速度随机度】
uniform float length_randomness : hint_range(0.0, 1.0) = 0.3;
uniform float speed_randomness : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	// 根据实际尺寸计算网格数量
	vec2 grid_size = vec2(
		max(1.0, floor(rect_size.x / bar_width_pixels)),
		max(1.0, floor(rect_size.y / grid_height_pixels))
	);
	
	// 将当前 UV 坐标离散化到局部格子的网格中
	vec2 grid_uv = floor(UV * grid_size) / grid_size;
	
	// --- 将随机种子融入正弦噪声计算中 ---
	float rand_length = fract(sin(dot(vec2(grid_uv.x + seed, 1.3), vec2(12.9898, 78.233))) * 43758.5453);
	float rand_speed  = fract(sin(dot(vec2(grid_uv.x - seed, 4.7), vec2(37.2411, 43.197))) * 75319.1235);
	
	// 使用非线性指数映射速度
	float exponent = mix(1.0, 1.0 + rand_speed * 5.0, speed_randomness);
	float column_progress = pow(progress, exponent);
	
	// 计算该格子的垂直位置判定阈值（从上到下）
	float threshold = (1.0 - grid_uv.y) * (1.0 - length_randomness) + (rand_length * length_randomness);
	
	// 抗锯齿过渡缓冲量
	float pixel_bleed = 1.5 / grid_size.y; 
	
	// --- 【核心修复逻辑】 ---
	// 1. 重新映射 threshold 的 range，上限卡在 (1.0 - pixel_bleed)，给抗锯齿留出安全带
	//    下限卡在 pixel_bleed，确保当 progress=1 时底部也能完全填满
	threshold = mix(pixel_bleed, 1.0 - pixel_bleed, threshold);
	
	// 2. 正常进行原本的阈值对比计算
	float diff = column_progress - (1.0 - threshold);
	float alpha = smoothstep(-pixel_bleed, 0.0, diff);
	
	// 3. 【双重保险】：如果外部传入的进度本身就是严格的 0.0，强制让 alpha 归零
	//    这样能百分之百规避不同显卡芯片由于浮点数截断精度不同带来的边缘溢出
	if (progress <= 0.0) {
		alpha = 0.0;
	}
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
