## 基础着色控制器
##
## 使用 Dictionary 存储：key = layer_id（决定顺序），value = Color。
## 计算渐变时按 key 升序排序，以 main_index（layer_id）为基准层（亮度 1.0），
## 向两侧分别用 back_brightness / front_brightness 渐变（范围 -1~1）。
## 应用时通过信号按 layer_id 发送颜色，由各层自行决定如何使用。
##
## 使用方式：在场景中把本节点勾选「Unique Name in Owner」，
## 这样各 ParallaxLayeri 可通过 %BaseColoredController 直接访问。
class_name BaseColoredController
extends Component

## 所有颜色计算完毕后发出
signal colors_applied
## 按 layer_id 发送对应颜色
signal layer_color_calculated(layer_id: int, color: Color)

@onready var level: Levels = $"../.."
@onready var main_light: PointLight2D = %MainLight

@export_category("基础颜色配置")
## key = layer_id（决定排序），value = 计算后的颜色。外部修改会自动同步应用
@export var colored_layers: Dictionary = {}: # int -> Color
	set(value):
		colored_layers = value
		_on_colors_changed()

var base_color: Color = Color.WHITE:
	set(value):
		base_color = value

## 作为基准色（亮度 = 1.0）的层的 layer_id
@export var main_index: int = 11:
	set(value):
		main_index = value
		_on_param_changed()

## 比 main_index 小的层的边界亮度（最靠后一层）
@export_range(-1.0, 1.0, 0.01) var back_brightness: float = 0.25:
	set(value):
		back_brightness = value
		_on_param_changed()

## 比 main_index 大的层的边界亮度（最靠前一层）
@export_range(-1.0, 1.0, 0.01) var front_brightness: float = 0.25:
	set(value):
		front_brightness = value
		_on_param_changed()

@export var auto_apply: bool = true

var _applied: bool = false
var _updating_colors: bool = false # 防止 set 循环


func init_var() -> void:
	clazz_name = "BaseColoredController"


func ready() -> void:
	base_color = level.level_background_color
	call_deferred("_wait_and_apply")


func _wait_and_apply() -> void:
	await get_tree().process_frame
	main_light.color = base_color
	if auto_apply:
		apply_colors()


func register_layer(layer: ParallaxLayeri) -> void:
	if colored_layers.has(layer.layer_id):
		return
	# 先占位，真正颜色由 apply_colors 计算
	colored_layers[layer.layer_id] = Color.WHITE
	if _applied:
		apply_colors()


func _on_param_changed() -> void:
	if not is_inside_tree():
		return
	main_light.color = base_color
	if colored_layers.is_empty():
		return
	apply_colors()


## colored_layers 被外部修改时同步发出信号
func _on_colors_changed() -> void:
	if _updating_colors:
		return
	if not is_inside_tree():
		return
	_emit_colors()


## 计算颜色 → 写入 colored_layers → 按 layer_id 发信号
## 以 main_index（layer_id）为基准（亮度 1.0），向后用 back_brightness、向前用 front_brightness 渐变
func apply_colors() -> void:
	if colored_layers.is_empty():
		return

	base_color = level.level_background_color
	if Global.back_ground_color:
		Global.back_ground_color.modulate = base_color

	var sorted_ids: Array = colored_layers.keys()
	sorted_ids.sort() # 按 layer_id 升序
	var count := sorted_ids.size()

	# 找到 main_index 对应的位置；若不存在则取插入点
	var main_pos: int = sorted_ids.find(main_index)
	if main_pos < 0:
		main_pos = sorted_ids.bsearch(main_index)
		main_pos = clampi(main_pos, 0, count - 1)

	var new_colors: Dictionary = {}
	for i in range(count):
		var brightness: float
		if i == main_pos:
			brightness = 1.0
		elif i < main_pos:
			# 从最靠后（i=0）的 back_brightness 渐变到 main_pos 的 1.0
			var t := 0.0 if main_pos <= 0 else float(i) / float(main_pos)
			brightness = lerpf(back_brightness, 1.0, t)
		else:
			# 从 main_pos 的 1.0 渐变到最靠前（i=count-1）的 front_brightness
			var t := 0.0 if main_pos >= count - 1 else float(i - main_pos) / float(count - 1 - main_pos)
			brightness = lerpf(1.0, front_brightness, t)

		var layer_id: int = sorted_ids[i]
		new_colors[layer_id] = Color(
			base_color.r * brightness,
			base_color.g * brightness,
			base_color.b * brightness,
			base_color.a
		)

	# 写入（用标志防止 set 回调死循环）
	_updating_colors = true
	colored_layers = new_colors
	_updating_colors = false

	_emit_colors()
	_applied = true
	colors_applied.emit()


## 只负责按当前 colored_layers（已按 key 排序）发送信号
func _emit_colors() -> void:
	var sorted_ids: Array = colored_layers.keys()
	sorted_ids.sort()
	for layer_id in sorted_ids:
		layer_color_calculated.emit(layer_id, colored_layers[layer_id])


func refresh() -> void:
	apply_colors()
