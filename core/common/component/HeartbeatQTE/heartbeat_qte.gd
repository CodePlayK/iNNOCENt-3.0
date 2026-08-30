extends Control

signal qte_finished(is_overall_success: bool, total_clicks: int, success_clicks: int)

@export_group("基础设置")
@export var line_width: float = 400.0       

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

@export_group("5 & 6. 形态与背景")
@export var wave_base_height: float = 1.0   
@export var wave_base_width: float = 1.0    
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.341) 

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

func _ready() -> void:
	cursor_x = line_width / 2.0
	current_line_color = baseline_default_color
	EventBus.start_qte.connect(start_qte)
	set_process(false)

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

func start_qte(total_spawn: int = 3, required_success: int = 2) -> void:
	total_blocks_to_spawn = max(1, total_spawn)
	required_success_count = clamp(required_success, 0, total_blocks_to_spawn)
	spawned_blocks_count = 0
	current_success_count = 0
	active_waves.clear()
	block_alpha = 0.0
	_force_stop_loop = false
	
	is_active = true
	set_process(true)
	_next_block_sequence()

func stop_qte() -> void:
	is_active = false
	is_block_moving = false
	active_waves.clear()
	block_alpha = 0.0
	_force_stop_loop = false
	if active_color_tween and active_color_tween.is_valid():
		active_color_tween.kill()
	set_process(false)
	queue_redraw()

func _next_block_sequence() -> void:
	if not is_active or _force_stop_loop: return
	if spawned_blocks_count >= total_blocks_to_spawn:
		is_block_moving = false
		return 
		
	spawned_blocks_count += 1
	current_speed = randf_range(min_speed, max_speed)
	
	target_x = line_width
	block_scale = 1.0 
	block_alpha = 1.0
	is_block_moving = true
	current_line_color = baseline_default_color

func _handle_single_result(is_success: bool) -> void:
	is_block_moving = false 
	current_line_color = success_color if is_success else fail_color
	
	if is_success:
		current_success_count += 1
		_spawn_wave_data(Vector2(cursor_x, size.y / 2.0))
		
		var tween = create_tween().set_parallel(true)
		var orig_pos = position
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", orig_pos - Vector2(10, 10), 0.05)
		
		var tween_back = create_tween().set_parallel(true)
		tween_back.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween_back.tween_property(self, "position", orig_pos, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		var orig_pos = position
		var tween = create_tween()
		for i in range(5):
			var offset_x = 12 if i % 2 == 0 else -12
			tween.tween_property(self, "position:x", orig_pos.x + offset_x, 0.03).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(self, "position:x", orig_pos.x, 0.04)
		
	var fade_time = min(block_fade_out_duration, block_spawn_interval)
	var anim_tween = create_tween().set_parallel(true)
	anim_tween.tween_property(self, "block_alpha", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(self, "block_scale", block_fade_out_scale, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if active_color_tween and active_color_tween.is_valid():
		active_color_tween.kill()
	active_color_tween = anim_tween
	active_color_tween.tween_property(self, "current_line_color", baseline_default_color, block_spawn_interval).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if current_success_count >= required_success_count:
		_force_stop_loop = true
	else:
		var potential_max_success = current_success_count + (total_blocks_to_spawn - spawned_blocks_count)
		if potential_max_success < required_success_count:
			_force_stop_loop = true
		
	if spawned_blocks_count < total_blocks_to_spawn and not _force_stop_loop:
		get_tree().create_timer(block_spawn_interval).timeout.connect(_next_block_sequence)

func _evaluate_overall_result() -> void:
	is_active = false
	set_process(false)
	var is_overall_success = current_success_count >= required_success_count
	qte_finished.emit(is_overall_success, total_blocks_to_spawn, current_success_count)

func _draw() -> void:
	var mid_y = size.y / 2.0 if size.y > 0 else 0.0
	var fx_zone = line_width * 0.15
	var fy_zone = 15.0 
	
	var seg_w = line_width / 16.0
	var seg_h = 60.0 / 8.0
	var start_y = mid_y - 30.0
	
	for r in range(8):
		for c in range(16):
			var pts = PackedVector2Array([
				Vector2(c * seg_w, start_y + r * seg_h), Vector2((c + 1) * seg_w, start_y + r * seg_h),
				Vector2((c + 1) * seg_w, start_y + (r + 1) * seg_h), Vector2(c * seg_w, start_y + (r + 1) * seg_h)
			])
			var clrs = PackedColorArray()
			for pt in pts:
				var ax = pt.x / fx_zone if pt.x < fx_zone else ((line_width - pt.x) / fx_zone if pt.x > line_width - fx_zone else 1.0)
				var rel_y = pt.y - start_y
				var ay = rel_y / fy_zone if rel_y < fy_zone else ((60.0 - rel_y) / fy_zone if rel_y > 45.0 else 1.0)
				clrs.append(Color(bg_color, bg_color.a * max(0.0, ax * ay)))
			draw_polygon(pts, clrs)

	# 【在此彻底修复】用数组索引 [0] 安全且精确地提取字典元素，规避类型报错
	var has_wave = active_waves.size() > 0
	var w_start = -1.0
	var w_end = -1.0
	if has_wave:
		var w = active_waves[0]
		w_start = w.pos.x + w.shift + w.points[0].x
		w_end = w.pos.x + w.shift + w.points[-1].x

	for i in range(int(line_width)):
		var fx = float(i)
		if has_wave and fx >= w_start and fx <= w_end: continue
		var ax = fx / fx_zone if fx < fx_zone else ((line_width - fx) / fx_zone if fx > line_width - fx_zone else 1.0)
		draw_line(Vector2(fx, mid_y), Vector2(fx + 1.0, mid_y), Color(current_line_color, max(0.0, ax)), line_thickness, true)
	
	if has_wave:
		var w = active_waves[0]
		var green_pts = PackedVector2Array()
		var green_clrs = PackedColorArray()
		for i in range(w.points.size()):
			var p = w.pos + Vector2(w.shift + w.points[i].x, w.points[i].y * w.wave_growth)
			green_pts.append(p)
			var ax = p.x / fx_zone if p.x < fx_zone else ((line_width - p.x) / fx_zone if p.x > line_width - fx_zone else 1.0)
			green_clrs.append(Color(current_line_color, w.alpha * max(0.0, ax)))
		draw_polyline_colors(green_pts, green_clrs, line_thickness, true)
			
	if is_block_moving or block_alpha > 0.0:
		var bx = max(0.0, target_x)
		var ax = bx / fx_zone if bx < fx_zone else ((line_width - bx) / fx_zone if bx > line_width - fx_zone else 1.0)
		draw_circle(Vector2(bx, mid_y), block_default_radius * block_scale, Color(current_line_color, block_alpha * max(0.0, ax)))
		
	var hl = cursor_length / 2.0
	var hw = cursor_wing_width / 2.0
	draw_line(Vector2(cursor_x, mid_y - hl), Vector2(cursor_x, mid_y + hl), cursor_color, cursor_width, true)
	draw_line(Vector2(cursor_x - hw, mid_y - hl), Vector2(cursor_x + hw, mid_y - hl), cursor_color, cursor_wing_thickness, true)
	draw_line(Vector2(cursor_x - hw, mid_y + hl), Vector2(cursor_x + hw, mid_y + hl), cursor_color, cursor_wing_thickness, true)

func _spawn_wave_data(start_pos: Vector2) -> void:
	var rh = randf_range(0.85, 1.15) * wave_base_height
	var rw = randf_range(0.9, 1.15) * wave_base_width
	active_waves.append({
		"points": [Vector2(-42.5*rw, 0), Vector2(-32.5*rw, -5*rh), Vector2(0.0, -70*rh), Vector2(15.0*rw, 35*rh), Vector2(30.0*rw, -15*rh), Vector2(42.5*rw, 0)],
		"pos": start_pos, "alpha": 1.0, "age": 0.0, "max_age": 0.75, "shift": 0.0, "max_shift": -260.0, "wave_growth": 0.0
	})
