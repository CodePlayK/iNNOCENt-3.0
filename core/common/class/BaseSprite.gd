@icon("res://addons/at-icons/node3d/smiley_face.svg")
extends Sprite2D
class_name BaseSprite

@export_group("颜色配置")
@export var enable_layer_color: bool = true:
	set(value):
		enable_layer_color = value
		_update_base_color()

@export var base_color: Color = Color.WHITE:
	set(value):
		base_color = value
		_update_base_color()
@export_range(0.0, 1.0) var base_color_override_scale: float = 0.5:
	set(value):
		base_color_override_scale = clampf(value, 0.0, 1.0)
		_update_base_color()

var layer_color: Color = Color.WHITE

@export_group("边缘光配置")
@export var rim_light_enable: bool = true:
	set(value):
		rim_light_enable = value
		_update_rim_shader()

@export_range(0, 20, 0.1) var rim_width_px: float = 3.0:
	set(value):
		rim_width_px = value
		_update_rim_shader()

@export_range(0, 10, 0.1) var rim_intensity: float = 0.6:
	set(value):
		rim_intensity = value
		_update_rim_shader()

@export_range(0, 10, 0.1) var rim_softness: float = 1.2:
	set(value):
		rim_softness = value
		_update_rim_shader()

@export var light_dir: Vector2 = Vector2(0.3, -0.5):
	set(value):
		light_dir = value
		_update_rim_shader()

@export_range(0, 10, 0.1) var distance_strength: float = 2.5:
	set(value):
		distance_strength = value
		_update_rim_shader()

@export_group("背后偏移提亮")
## 是否启用背后复制 Sprite
@export var back_offset: bool = true:
	set(value):
		back_offset = value
		_update_back_sprite()

## 背后 Sprite 相对当前 Sprite 的像素偏移
@export var back_offset_pixels: Vector2 = Vector2(-3, -2):
	set(value):
		back_offset_pixels = value
		_update_back_sprite()
		
##同步主sprite的modulate
@export var sync_modulate: bool = false:
	set(value):
		sync_modulate = value
		_update_back_sprite()

## 叠加在背后 Sprite 上的颜色（默认白色，用于提亮）
@export var back_overlay_color: Color = Color(1, 1, 1, 1):
	set(value):
		back_overlay_color = value
		_update_back_sprite()

## 从自己所在节点一路向上，找到第一个 ParallaxLayeri，并注册其 layer_id
var layer_id: int = -1
var parallax_layer: ParallaxLayeri = null
var _back_sprite: Sprite2D = null


func _ready() -> void:
	parallax_layer = _find_parent_parallax_layer()
	if parallax_layer:
		layer_id = parallax_layer.layer_id
		_register_to_controller()
	else:
		push_warning("%s 没有找到父级 ParallaxLayeri" % name)

	_update_rim_shader()

	# 开启变换通知，主 Sprite 移动/旋转/缩放时同步背后 Sprite
	set_notify_transform(true)

	# 延迟到下一帧，保证父节点和变换都已就绪
	call_deferred("_update_back_sprite")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_sync_back_sprite_transform()


func _update_base_color() -> void:
	if enable_layer_color:
		modulate = 	layer_color.lerp(base_color, base_color_override_scale)
	else:
		modulate = base_color


func _find_parent_parallax_layer() -> ParallaxLayeri:
	var node := get_parent()
	while node:
		if node is ParallaxLayeri:
			return node as ParallaxLayeri
		node = node.get_parent()
	return null


func _register_to_controller() -> void:
	var controller := %BaseColoredController as BaseColoredController
	if controller == null:
		call_deferred("_register_to_controller")
		return

	controller.register_layer(parallax_layer)
	if not controller.layer_color_calculated.is_connected(_on_layer_color_calculated):
		controller.layer_color_calculated.connect(_on_layer_color_calculated)


func _on_layer_color_calculated(index: int, color: Color) -> void:
	if index == layer_id:
		layer_color = color
		_update_base_color()
		_update_back_sprite()


func _update_rim_shader() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return

	var mat := material as ShaderMaterial
	if mat == null:
		return

	mat.set_shader_parameter("enable_rim", rim_light_enable)
	mat.set_shader_parameter("rim_width_px", rim_width_px)
	mat.set_shader_parameter("rim_intensity", rim_intensity)
	mat.set_shader_parameter("rim_softness", rim_softness)
	mat.set_shader_parameter("light_dir", light_dir)
	mat.set_shader_parameter("distance_strength", distance_strength)


## 只同步位置、旋转、缩放（轻量）
func _sync_back_sprite_transform() -> void:
	if _back_sprite == null or not is_instance_valid(_back_sprite):
		return
	if not back_offset:
		return

	_back_sprite.global_position = global_position + back_offset_pixels
	_back_sprite.rotation = rotation
	_back_sprite.scale = scale
	_back_sprite.light_mask = light_mask


## 创建 / 更新 / 销毁背后 Sprite（同级节点，用顺序控制前后）
func _update_back_sprite() -> void:
	# 还没进树时，延迟再试（解决加载时 setter 提前触发的问题）
	if not is_inside_tree():
		if back_offset:
			call_deferred("_update_back_sprite")
		return

	var parent := get_parent()
	if parent == null:
		return

	if not back_offset:
		_clear_back_sprite()
		return

	# 确保背后 Sprite 存在，并且是同级
	if _back_sprite == null or not is_instance_valid(_back_sprite):
		_back_sprite = Sprite2D.new()
		_back_sprite.name = name + "_BackOffset"
		parent.add_child(_back_sprite)
		if Engine.is_editor_hint():
			_back_sprite.owner = owner

	# 强制放到自己前面（更小的 index = 先绘制 = 在背后）
	if _back_sprite.get_index() >= get_index():
		parent.move_child(_back_sprite, get_index())

	# 复制关键视觉属性
	_back_sprite.texture = texture
	_back_sprite.region_enabled = region_enabled
	_back_sprite.region_rect = region_rect
	_back_sprite.hframes = hframes
	_back_sprite.vframes = vframes
	_back_sprite.frame = frame
	_back_sprite.flip_h = flip_h
	_back_sprite.flip_v = flip_v
	_back_sprite.centered = centered
	_back_sprite.offset = offset

	# 位置 / 旋转 / 缩放
	_back_sprite.global_position = global_position + back_offset_pixels
	_back_sprite.rotation = rotation
	_back_sprite.scale = scale

	# ---------- 真正提亮（加法混合） ----------
	var mat := _back_sprite.material as CanvasItemMaterial
	if mat == null:
		mat = CanvasItemMaterial.new()
		_back_sprite.material = mat
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_back_sprite.modulate = Color(
		back_overlay_color.r,
		back_overlay_color.g,
		back_overlay_color.b,
		back_overlay_color.a * modulate.a
	)


func _clear_back_sprite() -> void:
	if _back_sprite and is_instance_valid(_back_sprite):
		_back_sprite.queue_free()
	_back_sprite = null


func _exit_tree() -> void:
	_clear_back_sprite()
