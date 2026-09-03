extends Control
class_name HeartbeatResuscitationQTE
## 角色头顶小弹窗心跳复苏 QTE。小折线由 shader 绘制（不参与判定）。
## 调用 [method start_qte] 或 EventBus.start_heartbeat_qte。

signal qte_triggered(params: Dictionary)
signal qte_finished(result: Dictionary)

enum Phase { IDLE, PLAYING, RESULT }

const QRS_KEYS: Array[Vector2] = [
	Vector2(-0.90, 0.00),
	Vector2(-0.22, 0.00),
	Vector2(-0.12, -0.28),
	Vector2(0.00, 1.00),
	Vector2(0.12, -0.46),
	Vector2(0.26, 0.00),
	Vector2(0.90, 0.00),
]

const NOISE_MAT := preload("res://core/common/component/player_health_indicator/heartbeat_qte_mat.tres")

@export_group("QTE 规则")
@export var duration: float = 8.0
@export var heartbeat_count: int = 4
@export var required_hits: int = 2
@export var required_success: float = 2.0
@export var success_per_hit: float = 1.0
@export var min_hit_multiplier: float = 0.7
@export var max_hit_multiplier: float = 1.3
@export var hit_window: float = 14.0
@export var min_spawn_interval: float = 0.9
@export var max_spawn_interval: float = 1.6
@export var input_action: StringName = &""
@export var lock_player_on_start: bool = false
@export var start_on_ready: bool = false
@export var hide_on_finish: bool = true

@export_group("外观")
@export var line_color: Color = Color(1, 1, 1, 0.95)
@export var judgment_color: Color = Color(1, 1, 1, 0.9)
@export var line_width: float = 1.6
@export var scroll_speed: float = 78.0
@export var judgment_x_ratio: float = 0.18
@export var big_wave_amp_min: float = 0.52
@export var big_wave_amp_max: float = 0.78
@export var big_wave_width_min: float = 26.0
@export var big_wave_width_max: float = 40.0
@export var spawn_right_min: float = 0.70
@export var spawn_right_max: float = 0.96
## 峰值越过此比例（从右往左）时大折线必须长满。
@export var full_appear_x_ratio: float = 0.70

@export_group("结果")
@export var result_flash_time: float = 0.07
@export var result_hide_time: float = 0.16
@export var success_line_color: Color = Color(0.75, 1.0, 0.86, 1.0)
@export var fail_line_color: Color = Color(0.95, 0.32, 0.28, 1.0)

var success_score: float = 0.0
var hit_count: int = 0
var miss_count: int = 0
var result_blend: float = 0.0

var _phase: Phase = Phase.IDLE
var _elapsed: float = 0.0
var _spawned: int = 0
var _spawn_cooldown: float = 0.0
var _rng := RandomNumberGenerator.new()
var _waves: Array[HeartbeatWave] = []
var _cfg: Dictionary = {}
var _qte_success: bool = false
var _did_lock: bool = false
var _hit_flash: float = 0.0
var _miss_flash: float = 0.0
var _empty_flash: float = 0.0
var _time_scale: float = 1.0
var _finish_emitted: bool = false
var _run_id: int = 0
var _anim_tween: Tween
var _shake: float = 0.0
var _pulse: float = 0.0
var _rings: Array[Dictionary] = []
var _noise: ColorRect

class HeartbeatWave:
	var born: float = 0.0
	var world_x: float = 0.0
	var full_progress: float = 1.0
	var amplitude: float = 0.6
	var width: float = 32.0
	var judged: bool = false
	var hit: bool = false
	var flash: float = 0.0


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_ensure_noise()
	if EventBus.has_signal("start_heartbeat_qte") and not EventBus.start_heartbeat_qte.is_connected(start_qte):
		EventBus.start_heartbeat_qte.connect(start_qte)
	if start_on_ready:
		start_qte()
	else:
		hide()


func is_running() -> bool:
	return _phase != Phase.IDLE


func start_qte(params: Dictionary = {}) -> void:
	_run_id += 1
	_cfg = _build_config(params)
	_apply_config(_cfg)
	_hard_reset(true)
	_phase = Phase.PLAYING
	_spawn_cooldown = 0.12
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.78, 0.62)
	result_blend = 0.0
	show()
	_pop_in()
	if lock_player_on_start and EventBus.has_method("_player_control_lock"):
		EventBus._player_control_lock(true)
		_did_lock = true
	qte_triggered.emit(_cfg.duplicate())


func stop_qte() -> void:
	if _phase == Phase.IDLE:
		return
	_emit_finished(false, true)
	_hard_reset(false)


func get_active_config() -> Dictionary:
	return _cfg.duplicate()


func _ensure_noise() -> void:
	_noise = get_node_or_null("Noise") as ColorRect
	if _noise == null:
		_noise = ColorRect.new()
		_noise.name = "Noise"
		_noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_noise.show_behind_parent = true
		_noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_noise)
		move_child(_noise, 0)
	_noise.material = NOISE_MAT.duplicate()


func _pop_in() -> void:
	var tw := create_tween()
	_anim_tween = tw
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.06, 1.08), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _build_config(overrides: Dictionary) -> Dictionary:
	var cfg := {
		"duration": duration,
		"heartbeat_count": heartbeat_count,
		"required_hits": required_hits,
		"required_success": required_success,
		"success_per_hit": success_per_hit,
		"min_hit_multiplier": min_hit_multiplier,
		"max_hit_multiplier": max_hit_multiplier,
		"hit_window": hit_window,
		"min_spawn_interval": min_spawn_interval,
		"max_spawn_interval": max_spawn_interval,
		"scroll_speed": scroll_speed,
		"judgment_x_ratio": judgment_x_ratio,
		"input_action": String(input_action),
	}
	for k in overrides.keys():
		cfg[k] = overrides[k]
	return cfg


func _apply_config(cfg: Dictionary) -> void:
	duration = float(cfg.get("duration", duration))
	heartbeat_count = int(cfg.get("heartbeat_count", heartbeat_count))
	required_hits = int(cfg.get("required_hits", required_hits))
	required_success = float(cfg.get("required_success", required_success))
	success_per_hit = float(cfg.get("success_per_hit", success_per_hit))
	min_hit_multiplier = float(cfg.get("min_hit_multiplier", min_hit_multiplier))
	max_hit_multiplier = float(cfg.get("max_hit_multiplier", max_hit_multiplier))
	hit_window = float(cfg.get("hit_window", hit_window))
	min_spawn_interval = float(cfg.get("min_spawn_interval", min_spawn_interval))
	max_spawn_interval = float(cfg.get("max_spawn_interval", max_spawn_interval))
	scroll_speed = float(cfg.get("scroll_speed", scroll_speed))
	judgment_x_ratio = float(cfg.get("judgment_x_ratio", judgment_x_ratio))
	input_action = StringName(str(cfg.get("input_action", String(input_action))))


func _hard_reset(keep_visible: bool) -> void:
	_kill_tweens()
	_phase = Phase.IDLE
	_elapsed = 0.0
	_spawned = 0
	_spawn_cooldown = 0.0
	_waves.clear()
	_rings.clear()
	success_score = 0.0
	hit_count = 0
	miss_count = 0
	result_blend = 0.0
	_qte_success = false
	_hit_flash = 0.0
	_miss_flash = 0.0
	_empty_flash = 0.0
	_time_scale = 1.0
	_finish_emitted = false
	_shake = 0.0
	_pulse = 0.0
	scale = Vector2.ONE
	_unlock_player()
	if not keep_visible:
		hide()


func _kill_tweens() -> void:
	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = null


func _unlock_player() -> void:
	if _did_lock and EventBus.has_method("_player_control_lock"):
		EventBus._player_control_lock(false)
	_did_lock = false


func _input(event: InputEvent) -> void:
	if _phase != Phase.PLAYING:
		return
	var pressed := false
	if input_action != &"" and event.is_action_pressed(input_action):
		pressed = true
	elif input_action == &"" and event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_SPACE or k.keycode == KEY_SPACE:
			pressed = true
	if not pressed:
		return
	_try_hit()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	var dt := delta * _time_scale
	_elapsed += dt
	_hit_flash = maxf(_hit_flash - dt * 3.0, 0.0)
	_miss_flash = maxf(_miss_flash - dt * 2.4, 0.0)
	_empty_flash = maxf(_empty_flash - dt * 4.0, 0.0)
	_shake = maxf(_shake - dt * 9.0, 0.0)
	_pulse = maxf(_pulse - dt * 1.8, 0.0)
	for w in _waves:
		w.flash = maxf(w.flash - dt * 2.8, 0.0)
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i]["age"] = float(_rings[i]["age"]) + dt
		if float(_rings[i]["age"]) >= float(_rings[i]["life"]):
			_rings.remove_at(i)
	if _phase == Phase.PLAYING:
		_update_spawns(dt)
		_judge_passed()
		if _last_wave_passed() or _elapsed >= float(_cfg.get("duration", duration)):
			_resolve()
	_push_shader()
	queue_redraw()


func _scroll_px() -> float:
	return _elapsed * _speed()


func _push_shader() -> void:
	if _noise == null:
		return
	var mat := _noise.material as ShaderMaterial
	if mat == null:
		return
	var energy := 0.45 + 0.12 * sin(_elapsed * 3.4) + _pulse * 0.4 + (0.25 if _any_in_window() else 0.0)
	mat.set_shader_parameter("rect_size", size)
	mat.set_shader_parameter("scroll_px", _scroll_px())
	mat.set_shader_parameter("flash", _hit_flash - _miss_flash)
	mat.set_shader_parameter("energy", energy)
	var xs := PackedFloat32Array()
	var amps := PackedFloat32Array()
	var widths := PackedFloat32Array()
	var cuts := PackedFloat32Array()
	xs.resize(8)
	amps.resize(8)
	widths.resize(8)
	cuts.resize(8)
	var n := mini(_waves.size(), 8)
	for i in n:
		var w := _waves[i]
		var grow := _grow(w)
		var amp := w.amplitude * 0.5 * grow
		if w.judged and not w.hit:
			amp *= 0.22
		elif w.flash > 0.0:
			amp *= 1.0 + w.flash * 0.18
		var cell := maxf(size.x / 12.0, 6.0)
		xs[i] = _peak_x(w)
		amps[i] = amp
		widths[i] = lerpf(cell, w.width, grow)
		cuts[i] = 1.12
	mat.set_shader_parameter("w_count", n)
	mat.set_shader_parameter("w_x", xs)
	mat.set_shader_parameter("w_amp", amps)
	mat.set_shader_parameter("w_width", widths)
	mat.set_shader_parameter("w_cut", cuts)


func _judgment_x() -> float:
	return size.x * clampf(float(_cfg.get("judgment_x_ratio", judgment_x_ratio)), 0.08, 0.4)


func _baseline_y() -> float:
	return size.y * 0.5


func _speed() -> float:
	return maxf(float(_cfg.get("scroll_speed", scroll_speed)), 8.0)


func _last_wave_passed() -> bool:
	var count := int(_cfg.get("heartbeat_count", heartbeat_count))
	if _spawned < count or _waves.is_empty():
		return false
	for w in _waves:
		if not w.judged:
			return false
	return true


func _grow(w: HeartbeatWave) -> float:
	var x := _peak_x(w)
	var x_right := size.x
	var x_full := size.x * clampf(full_appear_x_ratio, 0.4, 0.9)
	var p := clampf(inverse_lerp(x_right, x_full, x), 0.0, 1.0)
	var dest := clampf(w.full_progress, 0.18, 1.0)
	var t := clampf(p / dest, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _peak_x(w: HeartbeatWave) -> float:
	return w.world_x - _scroll_px()


func _update_spawns(dt: float) -> void:
	if size.x < 8.0:
		return
	var count := int(_cfg.get("heartbeat_count", heartbeat_count))
	var limit := float(_cfg.get("duration", duration))
	if _spawned >= count:
		return
	_spawn_cooldown -= dt
	var remain := count - _spawned
	var min_i := float(_cfg.get("min_spawn_interval", min_spawn_interval))
	var force := remain > 0 and (limit - _elapsed) <= remain * min_i * 0.9
	if _spawn_cooldown > 0.0 and not force:
		return
	if not _spawn_wave():
		return
	_pulse = 1.0
	var max_i := float(_cfg.get("max_spawn_interval", max_spawn_interval))
	_spawn_cooldown = _rng.randf_range(min_i, maxf(max_i, min_i))


func _spawn_wave() -> bool:
	var jx := _judgment_x()
	var x0 := size.x * clampf(spawn_right_min, 0.45, 0.9)
	var x1 := size.x * clampf(spawn_right_max, spawn_right_min, 0.98)
	var spawn_x := _rng.randf_range(x0, x1)
	var est := maxf(spawn_x - jx, 8.0) / _speed()
	var limit := float(_cfg.get("duration", duration))
	if _elapsed + est > limit - 0.1:
		spawn_x = lerpf(x0, x1, 0.15)
		if _elapsed + maxf(spawn_x - jx, 8.0) / _speed() > limit - 0.05:
			return false
	var w := HeartbeatWave.new()
	w.born = _elapsed
	w.world_x = spawn_x + _scroll_px()
	w.full_progress = _rng.randf_range(0.22, 1.0)
	w.amplitude = _rng.randf_range(big_wave_amp_min, big_wave_amp_max)
	w.width = _rng.randf_range(big_wave_width_min, big_wave_width_max)
	_waves.append(w)
	_spawned += 1
	return true


func _try_hit() -> void:
	var window := float(_cfg.get("hit_window", hit_window))
	var best: HeartbeatWave = null
	var best_dist := window + 1.0
	var jx := _judgment_x()
	for w in _waves:
		if w.judged or _grow(w) < 0.82:
			continue
		var d := absf(_peak_x(w) - jx)
		if d <= window and d < best_dist:
			best = w
			best_dist = d
	if best == null:
		_empty_flash = 0.35
		_shake = 0.25
		return
	best.judged = true
	best.hit = true
	best.flash = 1.0
	hit_count += 1
	var acc := 1.0 - best_dist / maxf(window, 1.0)
	var mul := lerpf(float(_cfg.get("min_hit_multiplier", min_hit_multiplier)), float(_cfg.get("max_hit_multiplier", max_hit_multiplier)), acc)
	success_score += float(_cfg.get("success_per_hit", success_per_hit)) * mul
	_hit_flash = 1.0
	_shake = 0.35
	_pulse = 1.0
	_push_ring(jx, _baseline_y(), Color(0.7, 1.0, 0.84, 0.95), 0.38)
	_punch_scale(1.08)


func _judge_passed() -> void:
	var window := float(_cfg.get("hit_window", hit_window))
	var jx := _judgment_x()
	for w in _waves:
		if w.judged:
			continue
		if _peak_x(w) < jx - window:
			w.judged = true
			w.hit = false
			miss_count += 1
			_miss_flash = 0.85
			_shake = 0.5
			_push_ring(jx, _baseline_y(), Color(1.0, 0.34, 0.3, 0.95), 0.34)


func _push_ring(x: float, y: float, color: Color, life: float) -> void:
	_rings.append({"x": x, "y": y, "color": color, "age": 0.0, "life": life})


func _punch_scale(amt: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(amt, amt), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _resolve() -> void:
	if _phase != Phase.PLAYING:
		return
	for w in _waves:
		if not w.judged:
			w.judged = true
			w.hit = false
			miss_count += 1
	var need_hits := int(_cfg.get("required_hits", required_hits))
	var need_score := float(_cfg.get("required_success", required_success))
	_qte_success = hit_count >= need_hits and success_score >= need_score - 0.0001
	_phase = Phase.RESULT
	_push_ring(_judgment_x(), _baseline_y(), success_line_color if _qte_success else fail_line_color, 0.28)
	_play_result_flash(_qte_success)


func _play_result_flash(success: bool) -> void:
	var run_id := _run_id
	result_blend = 1.0
	if success:
		_hit_flash = 1.0
		modulate = success_line_color
	else:
		_miss_flash = 1.0
		modulate = fail_line_color
	var tw := create_tween()
	_anim_tween = tw
	tw.tween_interval(result_flash_time)
	tw.tween_property(self, "modulate:a", 0.0, result_hide_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector2(0.94, 0.9), result_hide_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	if run_id != _run_id:
		return
	_emit_finished(success, false)


func _emit_finished(success: bool, cancelled: bool) -> void:
	if _finish_emitted:
		return
	_finish_emitted = true
	var result := {
		"success": success and not cancelled,
		"cancelled": cancelled,
		"success_score": success_score,
		"required_success": float(_cfg.get("required_success", required_success)),
		"hit_count": hit_count,
		"miss_count": miss_count,
		"heartbeat_count": int(_cfg.get("heartbeat_count", heartbeat_count)),
		"required_hits": int(_cfg.get("required_hits", required_hits)),
		"elapsed": _elapsed,
		"duration": float(_cfg.get("duration", duration)),
	}
	_unlock_player()
	qte_finished.emit(result)
	if EventBus.has_signal("heartbeat_qte_finished"):
		EventBus.heartbeat_qte_finished.emit(result)
	_phase = Phase.IDLE
	scale = Vector2.ONE
	if hide_on_finish:
		hide()
		modulate = Color.WHITE


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var by := _baseline_y()
	var jx := _judgment_x()
	var col := _current_line_color()
	var sx := sin(_elapsed * 42.0) * _shake * 1.8
	draw_set_transform(Vector2(sx, sin(_elapsed * 2.1) * 0.6), 0.0, Vector2.ONE)
	var in_window := _any_in_window()
	_draw_window(jx, col, in_window)
	_draw_judgment(jx, by, col, in_window)
	_draw_rings()


func _current_line_color() -> Color:
	var col := line_color
	if _phase == Phase.RESULT:
		col = col.lerp(success_line_color if _qte_success else fail_line_color, result_blend)
	if _hit_flash > 0.0:
		col = col.lerp(Color(0.7, 1.0, 0.84, 1.0), _hit_flash * 0.65)
	if _miss_flash > 0.0:
		col = col.lerp(Color(1.0, 0.36, 0.32, 1.0), _miss_flash * 0.6)
	return col


func _any_in_window() -> bool:
	if _phase != Phase.PLAYING:
		return false
	var window := float(_cfg.get("hit_window", hit_window))
	var jx := _judgment_x()
	for w in _waves:
		if w.judged or _grow(w) < 0.82:
			continue
		if absf(_peak_x(w) - jx) <= window:
			return true
	return false


func _draw_window(jx: float, col: Color, in_window: bool) -> void:
	var window := float(_cfg.get("hit_window", hit_window))
	var a := 0.06 + (0.16 if in_window else 0.0) + _hit_flash * 0.18
	draw_rect(Rect2(jx - window, 3.0, window * 2.0, size.y - 6.0), Color(col.r, col.g, col.b, a), true)


func _draw_waveform(by: float, col: Color) -> void:
	var amp_mul := 1.0
	if _phase == Phase.RESULT and not _qte_success:
		amp_mul = lerpf(1.0, 0.0, result_blend)
	var glow := Color(col.r, col.g, col.b, col.a * 0.28)
	for w in _waves:
		var local := _wave_points(w, by, amp_mul)
		if local.size() < 2:
			continue
		draw_polyline(local, glow, line_width + 2.2, false)
		draw_polyline(local, col, line_width, false)


func _wave_points(w: HeartbeatWave, by: float, amp_mul: float) -> PackedVector2Array:
	var grow := _grow(w)
	if grow <= 0.02:
		return PackedVector2Array()
	var u_cut := 1.12
	var px := _peak_x(w)
	var amp := w.amplitude * size.y * 0.5 * grow * amp_mul
	if w.judged and not w.hit:
		amp *= 0.25
	elif w.flash > 0.0:
		amp *= 1.0 + w.flash * 0.2
	var pts := PackedVector2Array()
	for k in QRS_KEYS:
		if k.x > u_cut:
			break
		var x := px + k.x * w.width * 0.5
		var y := clampf(by - k.y * amp, 1.0, size.y - 1.0)
		pts.append(Vector2(x, y))
	return pts


func _draw_judgment(jx: float, by: float, col: Color, in_window: bool) -> void:
	var pulse := 1.0 + 0.1 * sin(_elapsed * 8.5) + (0.28 if in_window else 0.0) + _hit_flash * 0.35 - _empty_flash * 0.25
	var h := size.y * 0.42 * pulse
	var jc := judgment_color.lerp(col, 0.35)
	var a := 0.75 + (0.2 if in_window else 0.0)
	draw_line(Vector2(jx, by - h), Vector2(jx, by + h), Color(jc.r, jc.g, jc.b, a * 0.25), 5.0, false)
	draw_line(Vector2(jx, by - h), Vector2(jx, by + h), Color(jc.r, jc.g, jc.b, a), 1.4, false)
	var tick := 4.0 + (2.0 if in_window else 0.0)
	draw_line(Vector2(jx - tick, by - h), Vector2(jx + tick, by - h), Color(jc.r, jc.g, jc.b, a), 1.2, false)
	draw_line(Vector2(jx - tick, by + h), Vector2(jx + tick, by + h), Color(jc.r, jc.g, jc.b, a), 1.2, false)


func _draw_rings() -> void:
	for r in _rings:
		var t := float(r["age"]) / maxf(float(r["life"]), 0.01)
		var rad := lerpf(3.0, size.y * 0.7, t)
		var c: Color = r["color"]
		c.a *= 1.0 - t
		draw_arc(Vector2(float(r["x"]), float(r["y"])), rad, 0.0, TAU, 18, c, 1.3, false)
