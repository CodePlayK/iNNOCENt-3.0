## 基础着色控制器
##
## 收集所有 [BaseColoredLayer]，按 layer_id 从小到大排序，
## 以基础颜色为起点，按顺序逐渐降低亮度，只写入 layer 自身的 modulate。
##
## 使用方式：在场景中把本节点勾选「Unique Name in Owner」，
## 这样各 BaseColoredLayer 可通过 %BaseColoredController 直接访问。
class_name BaseColoredController extends Component
@onready var level: Levels = $"../.."

@export_category("基础颜色配置")
var base_color: Color = Color.WHITE:
	set(value):
		base_color = value
		_on_param_changed()

@export_range(0.0, 1.0, 0.01) var brightness_falloff: float = 0.12:
	set(value):
		brightness_falloff = value
		_on_param_changed()

@export_range(0.0, 1.0, 0.01) var min_brightness: float = 0.25:
	set(value):
		min_brightness = value
		_on_param_changed()

@export var auto_apply: bool = true

var colored_layers: Array[BaseColoredLayer] = []
var _applied: bool = false

func init_var() -> void:
	clazz_name = "BaseColoredController"

func ready() -> void:
	base_color = level.level_background_color
	call_deferred("_wait_and_apply")

func _wait_and_apply() -> void:
	await get_tree().process_frame
	_sort_layers()
	if auto_apply:
		apply_colors()

func register_layer(layer: BaseColoredLayer) -> void:
	if layer in colored_layers:
		return
	colored_layers.append(layer)
	if _applied:
		_sort_layers()
		apply_colors()

func _sort_layers() -> void:
	colored_layers.sort_custom(func(a: BaseColoredLayer, b: BaseColoredLayer) -> bool:
		return a.layer_id < b.layer_id
	)

## 参数变化时即时刷新
func _on_param_changed() -> void:
	if not is_inside_tree():
		return
	if colored_layers.is_empty():
		return
	apply_colors()

## 只染色 layer 自身，不管其他 node
func apply_colors() -> void:
	if colored_layers.is_empty():
		return

	var count := colored_layers.size()
	for i in range(count):
		var layer := colored_layers[i]
		var t := 0.0 if count <= 1 else float(i) / float(count - 1)
		var brightness := lerpf(1.0, min_brightness, t)

		layer.modulate = Color(
			base_color.r * brightness,
			base_color.g * brightness,
			base_color.b * brightness,
			base_color.a
		)

	_applied = true

func refresh() -> void:
	_sort_layers()
	apply_colors()
