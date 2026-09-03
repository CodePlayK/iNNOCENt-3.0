@icon("res://addons/at-icons/mesh/parking_sign.svg")

extends Component
class_name ParallaxScale2D
## 视差边界缩放组件（伪 3D 拉伸）
##
## 挂在 Sprite2D（或任意 Node2D）下，使父节点以左右边界为准做水平缩放，
## 左边界跟随 left_layer，右边界跟随 right_layer，产生透视拉伸效果。
##
## 位移来源（vegas 分支）：
##   ParallaxMoveData.dic_layers_move_data[layer.layer_id]
##
## 关键点：以「初始化时已有缩放」下的左右边界为基准，
## 而不是用未缩放的纹理宽度去加世界位移。
##
## 公式：
##   初始化时记录：
##     base_left_edge  = 父节点本地左边界（已含初始 scale）
##     base_right_edge = 父节点本地右边界
##     base_width      = base_right_edge - base_left_edge
##   每帧：
##     left_rel  = move[left]  - move[host]
##     right_rel = move[right] - move[host]
##     new_left  = base_left_edge  + left_rel
##     new_right = base_right_edge + right_rel
##     scale.x   = (new_right - new_left) / unscaled_width   （允许负缩放）
##     pos.x     按 centered / offset 对齐到新边界

#region Export

## 左边界跟随的目标视差层（ParallaxLayeri 节点）
@export var left_layer: ParallaxLayeri

## 右边界跟随的目标视差层（ParallaxLayeri 节点）
@export var right_layer: ParallaxLayeri

## 父节点当前所在的视差层。留空则自动向上检索第一个 ParallaxLayeri
@export var host_layer: ParallaxLayeri

## 额外水平错位（正右负左），在边界计算后再叠加
@export var offset_x: float = 0.0

## 是否在物理帧更新（与 Parallax / ParallaxSync 保持一致建议开启）
@export var use_physics_process: bool = true

## 开启后每秒打印一次调试信息
@export var debug: bool = false
#endregion


#region Runtime
var parallax_move_data: ParallaxMoveData
var _parent: Node2D

## 初始化时父节点的 position / scale
var _base_pos: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE

## 未缩放时的本地宽度（纹理/区域宽度，用于反推 scale.x）
var _unscaled_width: float = 1.0

## 初始化时（已含 base_scale）的左右边界（父节点本地坐标）
var _base_left_edge: float = 0.0
var _base_right_edge: float = 1.0
var _base_width: float = 1.0

## 是否以中心为原点（Sprite2D.centered 等）
var _is_centered: bool = true
## 非 centered 时，纹理左上角相对 position 的偏移（本地，未缩放）
var _offset_left: float = 0.0

var _host_id: String = ""
var _left_id: String = ""
var _right_id: String = ""
var _debug_timer: float = 0.0
var _used_move_data: bool = false
#endregion


func init_var() -> void:
	clazz_name = "ParallaxScale2D"


func ready() -> void:
	_parent = get_parent() as Node2D
	if _parent == null:
		set_process(false)
		set_physics_process(false)
		return

	_base_pos = _parent.position
	_base_scale = _parent.scale
	_resolve_geometry()

	# 加载 ParallaxMoveData
	if DataState and DataState.get("parallax_move_data_source_path"):
		var path: String = str(DataState.parallax_move_data_source_path)
		if ResourceLoader.exists(path):
			parallax_move_data = load(path) as ParallaxMoveData
	if parallax_move_data == null:
		var candidates := [
			"res://core/common/parallax/Parallax_move_data.tres",
			"res://core/common/parallax/parallax_move_data.tres",
			"res://core/common/resource/parallax/Parallax_move_data.tres",
			"res://core/common/parallax/ParallaxMoveData.tres",
		]
		for p in candidates:
			if ResourceLoader.exists(p):
				parallax_move_data = load(p) as ParallaxMoveData
				if parallax_move_data:
					break

	_resolve_host()
	_cache_layer_ids()

	if debug:
		_print_debug_info("ready")

	set_process(not use_physics_process)
	set_physics_process(use_physics_process)


func process(delta: float) -> void:
	_apply_scale(delta)


func physics_process(delta: float) -> void:
	_apply_scale(delta)


func _apply_scale(delta: float = 0.0) -> void:
	if not enable:
		return
	if _parent == null:
		return
	if not is_instance_valid(left_layer) or not is_instance_valid(right_layer):
		return
	if is_zero_approx(_unscaled_width) or is_zero_approx(_base_width):
		return

	if _left_id.is_empty() or _right_id.is_empty():
		_cache_layer_ids()

	var left_move: float = 0.0
	var right_move: float = 0.0
	var host_move: float = 0.0
	var source := "none"

	# ---------- 优先用 layer_id 从 ParallaxMoveData 读取 ----------
	if parallax_move_data and parallax_move_data.dic_layers_move_data:
		var data: Dictionary = parallax_move_data.dic_layers_move_data
		if (not _left_id.is_empty() and data.has(_left_id)) \
				or (not _right_id.is_empty() and data.has(_right_id)):
			left_move = float(data.get(_left_id, 0.0))
			right_move = float(data.get(_right_id, 0.0))
			if not _host_id.is_empty():
				host_move = float(data.get(_host_id, 0.0))
			source = "move_data"
			if not is_zero_approx(left_move) or not is_zero_approx(right_move):
				_used_move_data = true

	# ---------- 回退：global_position ----------
	if source == "none" or (not _used_move_data and is_zero_approx(left_move) and is_zero_approx(right_move)):
		var left_gx: float = left_layer.global_position.x
		var right_gx: float = right_layer.global_position.x
		var host_gx: float = host_layer.global_position.x if is_instance_valid(host_layer) else _parent.global_position.x
		left_move = left_gx
		right_move = right_gx
		host_move = host_gx
		source = "global_pos"

	var left_rel: float = left_move - host_move
	var right_rel: float = right_move - host_move

	# 以初始化时的左右边界为基准，叠加相对位移
	var new_left: float = _base_left_edge + left_rel
	var new_right: float = _base_right_edge + right_rel
	var new_width: float = new_right - new_left

	# 由目标宽度反推 scale.x（已正确处理初始缩放）
	var target_scale_x: float = new_width / _unscaled_width

	_parent.scale.x = target_scale_x
	_parent.scale.y = _base_scale.y

	# 位置：让左右边分别落到 new_left / new_right
	if _is_centered:
		var new_center: float = (new_left + new_right) * 0.5 + offset_x
		_parent.position = Vector2(new_center, _base_pos.y)
	else:
		var pos_x: float = new_left - _offset_left * target_scale_x + offset_x
		_parent.position = Vector2(pos_x, _base_pos.y)

	if debug:
		_debug_timer += delta
		if _debug_timer >= 1.0:
			_debug_timer = 0.0


## 解析初始化几何：未缩放宽、是否 centered、初始左右边界（已含 scale）
func _resolve_geometry() -> void:
	_unscaled_width = 1.0
	_is_centered = true
	_offset_left = 0.0

	if _parent is Sprite2D:
		var spr: Sprite2D = _parent as Sprite2D
		if spr.region_enabled:
			_unscaled_width = maxf(spr.region_rect.size.x, 0.001)
		elif spr.texture:
			_unscaled_width = maxf(spr.texture.get_size().x, 0.001)
		_is_centered = spr.centered
		_offset_left = spr.offset.x
	elif _parent is AnimatedSprite2D:
		var anim: AnimatedSprite2D = _parent as AnimatedSprite2D
		if anim.sprite_frames and anim.animation:
			var tex: Texture2D = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
			if tex:
				_unscaled_width = maxf(tex.get_size().x, 0.001)
		_is_centered = anim.centered
		_offset_left = anim.offset.x
	elif _parent is CanvasItem and _parent.has_method("get_rect"):
		var rect: Rect2 = _parent.get_rect()
		if rect.size.x > 0.001:
			_unscaled_width = rect.size.x
			_is_centered = is_zero_approx(rect.position.x + rect.size.x * 0.5)
			_offset_left = rect.position.x
	else:
		Debug.dprinterr(DebugCT.dp("ParallaxScale2D: 无法解析父节点几何，使用默认宽度 1.0",self))

	# 初始视觉宽度 = 未缩放宽 * 初始 scale.x
	_base_width = _unscaled_width * absf(_base_scale.x)

	# 初始左右边界（父节点本地坐标，已含初始 scale）
	if _is_centered:
		var half: float = _base_width * 0.5
		var off: float = _offset_left * _base_scale.x
		_base_left_edge = _base_pos.x - half + off
		_base_right_edge = _base_pos.x + half + off
	else:
		var left: float = _base_pos.x + _offset_left * _base_scale.x
		_base_left_edge = left
		_base_right_edge = left + _base_width


func _print_debug_info(when: String) -> void:
	print("======== ParallaxScale2D [%s] ========" % when)
	print("  parent: ", _parent)
	print("  base_pos: ", _base_pos, "  base_scale: ", _base_scale)
	print("  unscaled_w: ", _unscaled_width, "  base_width(已缩放): ", _base_width)
	print("  base_left: ", _base_left_edge, "  base_right: ", _base_right_edge)
	print("  centered: ", _is_centered, "  offset_left: ", _offset_left)
	print("  left_layer: ", left_layer, "  layer_id=", _left_id)
	print("  right_layer: ", right_layer, "  layer_id=", _right_id)
	print("  host_layer: ", host_layer, "  layer_id=", _host_id)
	print("  parallax_move_data: ", parallax_move_data)
	if parallax_move_data and parallax_move_data.dic_layers_move_data:
		print("  dic keys (前20): ", parallax_move_data.dic_layers_move_data.keys().slice(0, 20))
	print("=====================================")


func _get_layer_id(layer: ParallaxLayeri) -> String:
	if not is_instance_valid(layer):
		return ""
	if "layer_id" in layer:
		var id = layer.get("layer_id")
		if id == null:
			return ""
		return str(id)
	if "layerId" in layer:
		return str(layer.get("layerId"))
	return layer.name


func _resolve_host() -> void:
	if is_instance_valid(host_layer):
		return
	var n: Node = _parent
	while n:
		if n is ParallaxLayeri:
			host_layer = n as ParallaxLayeri
			return
		n = n.get_parent()


func _cache_layer_ids() -> void:
	_host_id = _get_layer_id(host_layer)
	_left_id = _get_layer_id(left_layer)
	_right_id = _get_layer_id(right_layer)


## 运行时重设基准（父节点位置/缩放被外部改过后调用）
func reset_base() -> void:
	if _parent == null:
		return
	_base_pos = _parent.position
	_base_scale = _parent.scale
	_resolve_geometry()


func set_layers(left: ParallaxLayeri, right: ParallaxLayeri) -> void:
	left_layer = left
	right_layer = right
	_cache_layer_ids()
	_used_move_data = false


func set_host_layer(layer: ParallaxLayeri) -> void:
	host_layer = layer
	_cache_layer_ids()
	_used_move_data = false
