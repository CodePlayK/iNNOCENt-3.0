extends Control

signal qte_finished(is_overall_success: bool, total_clicks: int, success_clicks: int)

@export_group("速度与随机度控制")
@export var min_speed: float = 200.0        
@export var max_speed: float = 450.0        
@export var current_speed: float = 300.0    

@export_group("1. 触发光标")
@export var cursor_width: float = 4.0       
@export var cursor_length: float = 50.0      
@export var cursor_wing_width: float = 16.0  
@export var cursor_wing_thickness: float = 2.0 
@export var cursor_color: Color = Color.WHITE
@export_range(0.0, 1.0) var cursor_relative_ratio: float = 0.25 

@export_group("2 & 3. 生命线与波浪")
@export var baseline_default_color: Color = Color.WHITE
@export var success_color: Color = Color.GREEN
@export var fail_color: Color = Color.RED
@export var line_thickness: float = 1.5      

@export_group("4. 触发圆圈形态")
@export var block_default_radius: float = 30.0 

@export_group("4. 触发圆圈时序控制")
@export var block_spawn_interval: float = 0.4  
@export var block_fade_out_duration: float = 0.35 
@export var block_fade_out_scale: float = 1.5   

@export_group("4. 小循环反馈幅度")
@export var success_shake_amplitude: float = 1.2 
@export var fail_shake_amplitude: float = 12.0   

@export_group("5 & 6. 形态与背景")
@export var wave_base_height: float = 1.0   
@export var wave_base_width: float = 1.0    
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.341) 

@export_group("7. 控件显隐动画")
@export var ui_fade_duration: float = 0.35  

var total_blocks_to_spawn: int = 1         
var required_success_count: int = 1        
var spawned_blocks_count: int = 0          
var current_success_count: int = 0         

var is_active: bool = false                 
var is_block_moving: bool = false           
var target_x: float = 0.0                    
var block_alpha: float = 0.0                 
var block_scale: float = 1.0                 
var current_line_color: Color = Color.WHITE 
var active_waves: Array = []                
var active_color_tween: Tween = null        
var cursor_x: float = 0.0                    

var _force_stop_loop: bool = false
var _draw_offset: Vector2 = Vector2.ZERO 
var _current_block_color: Color = Color.WHITE 

func _ready() -> void:
	_update_container_bounds()
	current_line_color = baseline_default_color
	modulate.a = 0.0
	scale = Vector2.ZERO
	EventBus.start_qte.connect(start_qte)
	item_rect_changed.connect(_update_container_bounds)
	set_process(false)

func _update_container_bounds() -> void:
	pivot_offset = size / 2.0
	cursor_x = size.x * cursor_relative_ratio

func _process(delta: float) -> void:
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
	
	if is_block_moving:
		target_x -= current_speed * delta
		var block_center_x = max(0.0, target_x)
		
		if (cursor_x - block_center_x) > block_default_radius:
			_handle_single_result(false)
		elif Input.is_action_just_pressed("ui_accept"):
			_handle_single_result(abs(cursor_x - block_center_x) <= block_default_radius)
			
	if is_active and not is_block_moving and (spawned_blocks_count >= total_blocks_to_spawn or _force_stop_loop):
		if active_waves.is_empty() and block_alpha <= 0.0:
			_evaluate_overall_result()
		
	queue_redraw()

func start_qte(total_spawn: int = 100, required_success: int = 2) -> void:
	_update_container_bounds()
	total_blocks_to_spawn = max(1, total_spawn)
	required_success_count = clamp(required_success, 0, total_blocks_to_spawn)
	spawned_blocks_count = 0
	current_success_count = 0
	active_waves.clear()
	block_alpha = 0.0
	_force_stop_loop = false
	current_line_color = baseline_default_color
	_draw_offset = Vector2.ZERO
	
	var show_tween = create_tween().set_parallel(true)
	show_tween.tween_property(self, "modulate:a", 1.0, ui_fade_duration * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	scale = Vector2(0.3, 0.3)
	show_tween.tween_property(self, "scale", Vector2.ONE, ui_fade_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	is_active = true
	set_process(true)
	_next_block_sequence()

func stop_qte() -> void:
	is_active = false
	is_block_moving = false
	active_waves.clear()
	block_alpha = 0.0
	_force_stop_loop = false
	_draw_offset = Vector2.ZERO
	if active_color_tween and active_color_tween.is_valid():
		active_color_tween.kill()
		
	_update_container_bounds()
	
	var hide_tween = create_tween().set_parallel(true)
	hide_tween.tween_property(self, "modulate:a", 0.0, ui_fade_duration * 0.5)
	hide_tween.tween_property(self, "scale", Vector2.ZERO, ui_fade_duration * 0.5)
	hide_tween.chain().tween_callback(set_process.bind(false))
	queue_redraw()

func _next_block_sequence() -> void:
	if not is_active or _force_stop_loop: return
	if spawned_blocks_count >= total_blocks_to_spawn:
		is_block_moving = false
		return 
		
	spawned_blocks_count += 1
	current_speed = randf_range(min_speed, max_speed)
	
	target_x = size.x
	block_scale = 1.0 
	block_alpha = 1.0
	is_block_moving = true
	current_line_color = baseline_default_color
	_current_block_color = baseline_default_color

func _handle_single_result(is_success: bool) -> void:
	is_block_moving = false 
	current_line_color = success_color if is_success else fail_color
	_current_block_color = success_color if is_success else fail_color
	
	var color_recovery_duration: float = 0.0
	
	if is_success:
		current_success_count += 1
		_spawn_wave_data(Vector2(cursor_x, pivot_offset.y))
		color_recovery_duration = 0.75
		
		var target_scale = Vector2(success_shake_amplitude, success_shake_amplitude)
		var offset_pixels = (success_shake_amplitude - 1.0) * 50.0
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", target_scale, 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "_draw_offset", Vector2(-offset_pixels, -offset_pixels), 0.05)
		
		var tween_back = create_tween().set_parallel(true)
		tween_back.chain().tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween_back.tween_property(self, "_draw_offset", Vector2.ZERO, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		color_recovery_duration = block_fade_out_duration
		
		var tween = create_tween()
		for i in range(5):
			var offset_x = fail_shake_amplitude if i % 2 == 0 else -fail_shake_amplitude
			tween.tween_property(self, "_draw_offset:x", offset_x, 0.03).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(self, "_draw_offset:x", 0.0, 0.04)
		
	var fade_time = min(block_fade_out_duration, block_spawn_interval)
	var anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(self, "block_alpha", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "block_scale", block_fade_out_scale, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if active_color_tween and active_color_tween.is_valid():
		active_color_tween.kill()
	active_color_tween = anim_tween
	
	active_color_tween.tween_property(
		self, 
		"current_line_color", 
		baseline_default_color, 
		color_recovery_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if current_success_count >= required_success_count:
		_force_stop_loop = true
	else:
		var potential_max_success = current_success_count + (total_blocks_to_spawn - spawned_blocks_count)
		if potential_max_success < required_success_count:
			_force_stop_loop = true
		
	if spawned_blocks_count < total_blocks_to_spawn and not _force_stop_loop:
		get_tree().create_tween().tween_callback(_next_block_sequence).set_delay(block_spawn_interval)

func _evaluate_overall_result() -> void:
	is_active = false
	var is_overall_success = current_success_count >= required_success_count
	var final_result_color = success_color if is_overall_success else fail_color
	
	_update_container_bounds()
	
	if active_color_tween and active_color_tween.is_valid():
		active_color_tween.kill()
		
	var hide_tween = create_tween().set_parallel(true)
	hide_tween.tween_property(self, "scale", Vector2(1.4, 1.4), ui_fade_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hide_tween.tween_property(self, "modulate:a", 0.0, ui_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hide_tween.tween_property(self, "current_line_color", final_result_color, ui_fade_duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	hide_tween.chain().tween_callback(func():
		set_process(false)
		qte_finished.emit(is_overall_success, total_blocks_to_spawn, current_success_count)
	)

func _draw() -> void:
	draw_set_transform(_draw_offset, 0.0, Vector2.ONE)

	var mid_y = pivot_offset.y
	var fx_zone = size.x * 0.15
	var fy_zone = 15.0 
	
	var seg_w = size.x / 16.0
	var seg_h = 60.0 / 8.0
	var start_y = mid_y - 30.0
	
	for r in range(8):
		for c in range(16):
			var pts = PackedVector2Array([
				Vector2(c * seg_w, start_y + r * seg_h), 
				Vector2((c + 1) * seg_w, start_y + r * seg_h),
				Vector2((c + 1) * seg_w, start_y + (r + 1) * seg_h), 
				Vector2(c * seg_w, start_y + (r + 1) * seg_h)
			])
			var clrs = PackedColorArray()
			for pt in pts:
				var ax = pt.x / fx_zone if pt.x < fx_zone else (
					(size.x - pt.x) / fx_zone if pt.x > size.x - fx_zone else 1.0
				)
				var rel_y = pt.y - start_y
				var ay = rel_y / fy_zone if rel_y < fy_zone else (
					(60.0 - rel_y) / fy_zone if rel_y > 45.0 else 1.0
				)
				clrs.append(Color(bg_color, bg_color.a * max(0.0, ax * ay)))
			draw_polygon(pts, clrs)

	# ==========================================================================
	# 【绝对无瑕修复】：隔离别名和作用域，直接从数组头部取字典元素进行直线划分计算
	# ==========================================================================
	var has_wave = active_waves.size() > 0
	var w_start = -1.0
	var w_end = -1.0
	
	if has_wave:
		var current_wave: Dictionary = active_waves[0] as Dictionary
		var points_array: Array = current_wave.get("points", [])
		w_start = current_wave.pos.x + current_wave.shift + points_array[0].x
		w_end = current_wave.pos.x + current_wave.shift + points_array[-1].x

	for i in range(int(size.x)):
		var fx = float(i)
		if has_wave and fx >= w_start and fx <= w_end: 
			continue
			
		var ax = fx / fx_zone if fx < fx_zone else (
			(size.x - fx) / fx_zone if fx > size.x - fx_zone else 1.0
		)
		draw_line(
			Vector2(fx, mid_y), 
			Vector2(fx + 1.0, mid_y), 
			Color(current_line_color, max(0.0, ax)), 
			line_thickness, 
			true
		)
	
	if has_wave:
		var current_wave: Dictionary = active_waves[0] as Dictionary
		var points_array: Array = current_wave.get("points", [])
		var green_pts = PackedVector2Array()
		var green_clrs = PackedColorArray()
		
		for i in range(points_array.size()):
			var p = current_wave.pos + Vector2(
				current_wave.shift + points_array[i].x, 
				points_array[i].y * current_wave.wave_growth
			)
			green_pts.append(p)
			
			var ax = p.x / fx_zone if p.x < fx_zone else (
				(size.x - p.x) / fx_zone if p.x > size.x - fx_zone else 1.0
			)
			green_clrs.append(Color(current_line_color, current_wave.alpha * max(0.0, ax)))
			
		draw_polyline_colors(green_pts, green_clrs, line_thickness, true)
			
	if is_block_moving or block_alpha > 0.0:
		var bx = max(0.0, target_x)
		var ax = bx / fx_zone if bx < fx_zone else (
			(size.x - bx) / fx_zone if bx > size.x - fx_zone else 1.0
		)
		draw_circle(
			Vector2(bx, mid_y), 
			block_default_radius * block_scale, 
			Color(_current_block_color, block_alpha * max(0.0, ax))
		)
		
	var hl = cursor_length / 2.0
	var hw = cursor_wing_width / 2.0
	
	draw_line(Vector2(cursor_x, mid_y - hl), Vector2(cursor_x, mid_y + hl), cursor_color, cursor_width, true)
	draw_line(Vector2(cursor_x - hw, mid_y - hl), Vector2(cursor_x + hw, mid_y - hl), cursor_color, cursor_wing_thickness, true)
	draw_line(Vector2(cursor_x - hw, mid_y + hl), Vector2(cursor_x + hw, mid_y + hl), cursor_color, cursor_wing_thickness, true)

func _spawn_wave_data(start_pos: Vector2) -> void:
	var rh = randf_range(0.85, 1.15) * wave_base_height
	var rw = randf_range(0.9, 1.15) * wave_base_width
	
	active_waves.append({
		"points": [
			Vector2(-42.5 * rw, 0),
			Vector2(-32.5 * rw, -5 * rh),
			Vector2(0.0, -70 * rh),
			Vector2(15.0 * rw, 35 * rh),
			Vector2(30.0 * rw, -15 * rh),
			Vector2(42.5 * rw, 0)
		],
		"pos": start_pos,
		"alpha": 1.0,
		"age": 0.0,
		"max_age": 0.75,
		"shift": 0.0,
		"max_shift": -260.0,
		"wave_growth": 0.0
	})
