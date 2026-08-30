extends Control

# ==============================================================================
# @export 导出参数配置区
# ==============================================================================

@export_group("基础设置 (Base Settings)")
@export var line_width: float = 400.0       
@export var speed: float = 300.0            

@export_group("1. 触发光标 (Cursor)")
@export var cursor_width: float = 4.0       # 光标主线粗细
@export var cursor_length: float = 50.0      # 光标主线总长度
@export var cursor_wing_width: float = 16.0  # 顶部/底部横线宽度
@export var cursor_wing_thickness: float = 2.0 # 横线粗细
@export var cursor_color: Color = Color.WHITE

@export_group("2 & 3. 生命线与波浪颜色/粗细 (Lifeline & Wave)")
@export var baseline_default_color: Color = Color(1.0, 1.0, 1.0)
@export var success_color: Color = Color.GREEN
@export var fail_color: Color = Color.RED
@export var line_thickness: float = 1.5      # 生命线与波浪同步的粗细

@export_group("4. 触发圆圈 (Trigger Block)")
@export var block_default_radius: float = 30.0 # 触发圆形的半径 (实际触发与显示大小完全以此为准)
@export var block_fade_out_duration: float = 0.35 # 消散时长
@export var block_fade_out_scale: float = 1.5   # 消散时的触发大小缩放

@export_group("5. 波浪形态 (Wave)")
@export var wave_base_height: float = 1.0   # 波浪整体高度缩放系数值
@export var wave_base_width: float = 1.0    # 波浪整体宽度(频率)缩放系数值

@export_group("6. 背景颜色 (Background)")
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.341) # 默认背景色

# ==============================================================================
# 运行时内部变量
# ==============================================================================
var is_active: bool = true
var target_x: float = 0.0                    
var cursor_x: float = 0.0                    
var block_alpha: float = 0.0                 
var block_scale: float = 1.0                 
var current_line_color: Color = Color(1.0, 1.0, 1.0)
var active_waves: Array = []

# ==============================================================================
# 生命周期与逻辑处理
# ==============================================================================
func _ready() -> void:
	cursor_x = line_width / 2.0
	reset_qte()

func _process(delta: float) -> void:
	update_waves(delta)
	
	if not is_active:
		queue_redraw()
		return

	target_x -= speed * delta
	
	# 获取当前圆心坐标
	var block_center_x = max(0.0, target_x)
	
	# 修复漏检：如果圆圈已经彻底向左滚出光标范围（圆心到光标距离 > 半径），自动判定失败
	if (cursor_x - block_center_x) > block_default_radius:
		on_fail()
		return 
		
	if Input.is_action_just_pressed("ui_accept"):
		check_qte_success()
		
	queue_redraw()

# 【核心修复】修改判定逻辑为真正的圆形范围检测
func check_qte_success() -> void:
	var block_center_x = max(0.0, target_x)
	# 计算光标到圆心的绝对水平距离
	var distance = abs(cursor_x - block_center_x)
	
	# 只有当距离小于或等于设定的半径时，才算成功
	if distance <= block_default_radius:
		on_success()
	else:
		on_fail()

func reset_qte() -> void:
	target_x = line_width
	is_active = true
	current_line_color = baseline_default_color
	block_scale = 1.0 
	
	var fade_tween = create_tween()
	block_alpha = 0.0
	fade_tween.tween_property(self, "block_alpha", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# ==============================================================================
# 绘制逻辑 (Draw Logic)
# ==============================================================================
func _draw() -> void:
	var mid_y = size.y / 2.0 if size.y > 0 else 0.0
	var fade_zone_x = line_width * 0.15
	var bg_height = 60.0 
	var fade_zone_y = bg_height * 0.25
	
	draw_qte_bg_quad_fade(mid_y, fade_zone_x, fade_zone_y, bg_height)

	var has_green_wave = active_waves.size() > 0
	var current_wave = null
	var w_start_x = 0.0
	var w_end_x = 0.0
	
	if has_green_wave:
		current_wave = active_waves[0]
		var wave_center = current_wave.pos.x + current_wave.shift
		w_start_x = wave_center + current_wave.points[0].x
		w_end_x = wave_center + current_wave.points[-1].x

	for i in range(int(line_width)):
		var fx = float(i)
		if has_green_wave and fx >= w_start_x and fx <= w_end_x:
			continue
			
		var edge_a = 1.0
		if fx < fade_zone_x: edge_a = fx / fade_zone_x
		elif fx > line_width - fade_zone_x: edge_a = (line_width - fx) / fade_zone_x
		
		var c = current_line_color
		c.a = edge_a
		draw_line(Vector2(fx, mid_y), Vector2(fx + 1.0, mid_y), c, line_thickness, true)
	
	if has_green_wave:
		draw_success_wave(current_wave, fade_zone_x)
			
	draw_qte_block(mid_y, fade_zone_x)
	draw_qte_cursor(mid_y)

func draw_qte_bg_quad_fade(mid_y: float, fade_zone_x: float, fade_zone_y: float, total_h: float) -> void:
	var cols = 16
	var rows = 8
	var seg_w = line_width / cols
	var seg_h = total_h / rows
	var start_y = mid_y - total_h / 2.0
	
	for r in range(rows):
		for c in range(cols):
			var x1 = c * seg_w
			var x2 = (c + 1) * seg_w
			var y1 = start_y + r * seg_h
			var y2 = start_y + (r + 1) * seg_h
			
			var pts = PackedVector2Array([
				Vector2(x1, y1), Vector2(x2, y1),
				Vector2(x2, y2), Vector2(x1, y2)
			])
			
			var clrs = PackedColorArray()
			for pt in pts:
				var ax = 1.0
				if pt.x < fade_zone_x: ax = pt.x / fade_zone_x
				elif pt.x > line_width - fade_zone_x: ax = (line_width - pt.x) / fade_zone_x
				
				var ay = 1.0
				var rel_y = pt.y - start_y
				if rel_y < fade_zone_y: ay = rel_y / fade_zone_y
				elif rel_y > total_h - fade_zone_y: ay = (total_h - rel_y) / fade_zone_y
				
				var final_c = bg_color
				final_c.a *= (ax * ay)
				clrs.append(final_c)
				
			draw_polygon(pts, clrs)

func draw_success_wave(wave: Dictionary, fade_zone: float) -> void:
	var current_pos = wave.pos + Vector2(wave.shift, 0)
	var green_polyline: PackedVector2Array = PackedVector2Array()
	var green_colors: PackedColorArray = PackedColorArray()
	
	for i in range(wave.points.size()):
		var p = current_pos + Vector2(wave.points[i].x, wave.points[i].y * wave.wave_growth)
		green_polyline.append(p)
		
		var edge_a = 1.0
		if p.x < fade_zone: edge_a = max(0.0, p.x / fade_zone)
		elif p.x > line_width - fade_zone: edge_a = max(0.0, (line_width - p.x) / fade_zone)
		
		var gc = current_line_color
		gc.a = wave.alpha * edge_a
		green_colors.append(gc)
		
	draw_polyline_colors(green_polyline, green_colors, line_thickness, true)

func draw_qte_block(mid_y: float, fade_zone: float) -> void:
	if block_alpha > 0.0:
		var block_center_x = max(0.0, target_x)
		var edge_fade = 1.0
		if block_center_x < fade_zone: edge_fade = block_center_x / fade_zone
		elif block_center_x > line_width - fade_zone: edge_fade = (line_width - block_center_x) / fade_zone
		
		var fill_color = current_line_color
		fill_color.a = block_alpha * edge_fade
		# 绘制位置和范围判定完全同步
		draw_circle(Vector2(block_center_x, mid_y), block_default_radius * block_scale, fill_color)

func draw_qte_cursor(mid_y: float) -> void:
	var half_len = cursor_length / 2.0
	var half_wing = cursor_wing_width / 2.0
	
	draw_line(Vector2(cursor_x, mid_y - half_len), Vector2(cursor_x, mid_y + half_len), cursor_color, cursor_width, true)
	draw_line(Vector2(cursor_x - half_wing, mid_y - half_len), Vector2(cursor_x + half_wing, mid_y - half_len), cursor_color, cursor_wing_thickness, true)
	draw_line(Vector2(cursor_x - half_wing, mid_y + half_len), Vector2(cursor_x + half_wing, mid_y + half_len), cursor_color, cursor_wing_thickness, true)

# ==============================================================================
# QTE 结果触发状态
# ==============================================================================
func on_success() -> void:
	is_active = false 
	current_line_color = success_color
	spawn_wave_data(Vector2(cursor_x, size.y / 2.0))
	fade_out_block()
	
	var tween = create_tween().set_parallel(true)
	var orig_pos = position
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", orig_pos - Vector2(10, 10), 0.05)
	
	var tween_back = create_tween().set_parallel(true)
	tween_back.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween_back.tween_property(self, "position", orig_pos, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	var color_tween = create_tween()
	color_tween.tween_property(self, "current_line_color", baseline_default_color, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	get_tree().create_timer(1.2).timeout.connect(reset_qte)

func on_fail() -> void:
	is_active = false 
	current_line_color = fail_color
	fade_out_block()
	
	var orig_pos = position
	var tween = create_tween()
	for i in range(5):
		var offset_x = 12 if i % 2 == 0 else -12
		tween.tween_property(self, "position:x", orig_pos.x + offset_x, 0.03).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position:x", orig_pos.x, 0.04)
	
	var color_tween = create_tween()
	color_tween.tween_property(self, "current_line_color", baseline_default_color, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	get_tree().create_timer(1.2).timeout.connect(reset_qte)

func fade_out_block() -> void:
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "block_alpha", 0.0, block_fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(self, "block_scale", block_fade_out_scale, block_fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func spawn_wave_data(start_pos: Vector2) -> void:
	var rand_height_factor = randf_range(0.85, 1.15) * wave_base_height
	var rand_width_factor = randf_range(0.9, 1.15) * wave_base_width
	
	var pts = [
		Vector2(-42.5 * rand_width_factor, 0),
		Vector2(-32.5 * rand_width_factor, -5 * rand_height_factor),
		Vector2(0.0, -70 * rand_height_factor),     
		Vector2(15.0 * rand_width_factor, 35 * rand_height_factor),
		Vector2(30.0 * rand_width_factor, -15 * rand_height_factor),
		Vector2(42.5 * rand_width_factor, 0)
	]

	active_waves.append({
		"points": pts,
		"pos": start_pos,
		"alpha": 1.0,
		"age": 0.0,
		"max_age": 0.75, 
		"shift": 0.0, 
		"max_shift": -260.0, 
		"wave_growth": 0.0
	})
func update_waves(delta: float) -> void:
	var to_remove = []
	
	for wave in active_waves:
		wave.age += delta
		var progress = wave.age / wave.max_age
		
		if progress >= 1.0:
			to_remove.append(wave)
		else:
			wave.shift = progress * wave.max_shift
			wave.wave_growth = 1.0 - exp(-35.0 * progress)
			
	for wave in to_remove:
		active_waves.erase(wave)
