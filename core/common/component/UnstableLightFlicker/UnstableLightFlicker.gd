class_name UnstableLightFlicker
extends Node

## 可同时控制多个 PointLight2D，模拟电压不稳时的同步闪烁
## 每次闪烁 = 连续多次极短闪烁（次数随机） + 最后平滑恢复到原亮度

@export_group("目标灯光")
## 要控制的灯光列表。可同时添加多个 PointLight2D，它们会同步闪烁
@export var target_lights: Array[PointLight2D] = []:
	set(value):
		target_lights = value
		_cache_originals()

@export_group("闪烁节奏")
## 是否启用闪烁效果
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not enabled:
			_restore_immediate()

## 两次「闪烁事件」之间的最小间隔（秒）
@export_range(0.1, 30.0, 0.05) var interval_min: float = 1.4:
	set(value):
		interval_min = value

## 两次「闪烁事件」之间的最大间隔（秒）
@export_range(0.1, 60.0, 0.05) var interval_max: float = 4.8:
	set(value):
		interval_max = value

@export_group("单次闪烁事件（连续短闪）")
## 每次闪烁事件中，连续极短闪烁次数的最小值
@export_range(1, 12, 1) var flicker_times_min: int = 2:
	set(value):
		flicker_times_min = value

## 每次闪烁事件中，连续极短闪烁次数的最大值（会在 min~max 之间随机）
@export_range(1, 12, 1) var flicker_times_max: int = 5:
	set(value):
		flicker_times_max = value

## 每次极短闪烁时，灯光处于最暗状态的时间（秒）
@export_range(0.01, 0.2, 0.005) var short_dim_time: float = 0.035:
	set(value):
		short_dim_time = value

## 两次极短闪烁之间的间隔时间（秒）
@export_range(0.01, 0.25, 0.005) var short_gap_time: float = 0.045:
	set(value):
		short_gap_time = value

## 闪烁时最低亮度比例（相对原 energy）
@export_range(0.0, 1.0, 0.01) var dim_ratio: float = 0.08:
	set(value):
		dim_ratio = value

## 极短闪烁之间回升到的临时亮度比例
@export_range(0.1, 1.0, 0.01) var mid_ratio: float = 0.55:
	set(value):
		mid_ratio = value

@export_group("最终恢复过程")
## 连续短闪结束后，平滑恢复到原亮度所需时间（秒）
@export_range(0.05, 3.0, 0.01) var recovery_time: float = 0.65:
	set(value):
		recovery_time = value

## 恢复时的缓动类型
@export var recovery_ease: Tween.EaseType = Tween.EASE_OUT:
	set(value):
		recovery_ease = value

## 恢复时的过渡曲线
@export var recovery_trans: Tween.TransitionType = Tween.TRANS_QUART:
	set(value):
		recovery_trans = value

@export_group("额外真实感（可选）")
## 是否在闪烁时同时轻微改变颜色
@export var affect_color: bool = true:
	set(value):
		affect_color = value

## 闪烁时颜色向目标色靠拢的程度（0~1）
@export_range(0.0, 1.0, 0.01) var color_shift_amount: float = 0.4:
	set(value):
		color_shift_amount = value

## 闪烁时偏向的颜色（建议偏暖）
@export var flicker_color: Color = Color(1.0, 0.75, 0.4):
	set(value):
		flicker_color = value

# -------------------- 内部变量 --------------------
var _originals: Dictionary = {}  # light -> { "energy": float, "color": Color }
var _time_left: float = 0.0
var _is_flickering: bool = false
var _tween: Tween


func _ready() -> void:
	# 如果列表为空，且父节点是 PointLight2D，则自动加入
	if target_lights.is_empty():
		var parent = get_parent()
		if parent is PointLight2D:
			target_lights = [parent]
	
	_cache_originals()
	_time_left = _get_next_interval()


func _process(delta: float) -> void:
	if not enabled or target_lights.is_empty():
		return
	
	if _is_flickering:
		return
	
	_time_left -= delta
	if _time_left <= 0.0:
		_start_flicker_event()
		_time_left = _get_next_interval()


func _cache_originals() -> void:
	_originals.clear()
	for light in target_lights:
		if light and is_instance_valid(light):
			_originals[light] = {
				"energy": light.energy,
				"color": light.color
			}


func _get_next_interval() -> float:
	return randf_range(interval_min, interval_max)


func _get_flicker_times() -> int:
	var mini = mini(flicker_times_min, flicker_times_max)
	var maxi = maxi(flicker_times_min, flicker_times_max)
	return randi_range(mini, maxi)


func _start_flicker_event() -> void:
	# 清理无效灯光
	target_lights = target_lights.filter(func(l): return l != null and is_instance_valid(l))
	if target_lights.is_empty():
		return
	
	_is_flickering = true
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	
	var times = _get_flicker_times()
	
	for i in range(times):
		_tween.tween_callback(_set_dim)
		_tween.tween_interval(short_dim_time)
		
		if i < times - 1:
			_tween.tween_callback(_set_mid)
			_tween.tween_interval(short_gap_time)
	
	# 最终恢复
	_tween.set_ease(recovery_ease)
	_tween.set_trans(recovery_trans)
	
	for light in target_lights:
		if not _originals.has(light):
			continue
		var orig = _originals[light]
		_tween.parallel().tween_property(light, "energy", orig.energy, recovery_time)
		if affect_color:
			_tween.parallel().tween_property(light, "color", orig.color, recovery_time)
	
	_tween.tween_callback(_on_flicker_finished)


func _set_dim() -> void:
	for light in target_lights:
		if not is_instance_valid(light) or not _originals.has(light):
			continue
		var orig = _originals[light]
		light.energy = orig.energy * dim_ratio
		if affect_color:
			light.color = orig.color.lerp(flicker_color, color_shift_amount)


func _set_mid() -> void:
	for light in target_lights:
		if not is_instance_valid(light) or not _originals.has(light):
			continue
		var orig = _originals[light]
		light.energy = orig.energy * mid_ratio
		if affect_color:
			light.color = orig.color.lerp(flicker_color, color_shift_amount * 0.5)


func _on_flicker_finished() -> void:
	_is_flickering = false
	for light in target_lights:
		if is_instance_valid(light) and _originals.has(light):
			var orig = _originals[light]
			light.energy = orig.energy
			if affect_color:
				light.color = orig.color


func _restore_immediate() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_is_flickering = false
	for light in target_lights:
		if is_instance_valid(light) and _originals.has(light):
			var orig = _originals[light]
			light.energy = orig.energy
			light.color = orig.color


## 手动触发一次完整的闪烁事件
func trigger_flicker() -> void:
	if not _is_flickering:
		_start_flicker_event()


## 重新记录所有灯光当前的 energy 和 color 作为原始值
func recache_originals() -> void:
	_cache_originals()


## 添加一个灯光到控制列表
func add_light(light: PointLight2D) -> void:
	if light and not target_lights.has(light):
		target_lights.append(light)
		_cache_originals()


## 从控制列表中移除一个灯光
func remove_light(light: PointLight2D) -> void:
	target_lights.erase(light)
	_originals.erase(light)
