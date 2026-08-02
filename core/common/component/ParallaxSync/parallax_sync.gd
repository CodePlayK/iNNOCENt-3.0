extends Node
class_name ParallaxSync
## 视差同步组件
##
## 挂在任意 Node2D 父节点下，使父节点的水平位移与目标视差层完全同步，
## 效果上等同于父节点处于该目标层中。
##
## 位移公式（本地/父节点坐标系）：
##   parent.x = 初始x + (move[target_layer] - move[host_layer]) * offset_scale
## host 为父节点实际所在层；若挂在速度 0 的主层，host_layer 可留空。


#region Export
## 父节点当前所在的视差层名（与 ParallaxLayeri 节点名一致）
## 留空则宿主累计位移按 0 计算
@export var enable: bool = true
@export var host_layer: String = ""

## 要同步跟随的目标视差层名
@export var target_layer: String = "ParallaxLayer_0"

## 位移缩放（1 = 与目标层 1:1）
@export var offset_scale: float = 1.0

## 额外水平错位（正右负左）
@export var offset_x: float = 0.0

## 是否在物理帧更新（与 Parallax 一致建议开启）
@export var use_physics_process: bool = true
#endregion


#region Runtime
var parallax_move_data: ParallaxMoveData
## 父节点初始 position（每帧以此为基准，避免累加误差）
var _base_parent_pos: Vector2 = Vector2.ZERO
var _parent: Node2D
#endregion


func _ready() -> void:
	_parent = get_parent() as Node2D
	if _parent == null:
		push_error("ParallaxSync: 父节点必须是 Node2D")
		set_process(false)
		set_physics_process(false)
		return

	_base_parent_pos = _parent.position
	parallax_move_data = preload(DataState.parallax_move_data_source_path)

	set_process(not use_physics_process)
	set_physics_process(use_physics_process)


func _process(_delta: float) -> void:
	_sync_parent()


func _physics_process(_delta: float) -> void:
	_sync_parent()


func _sync_parent() -> void:
	if !enable:return
	if _parent == null or parallax_move_data == null:
		return
	if target_layer.is_empty():
		return

	var data: Dictionary = parallax_move_data.dic_layers_move_data
	if not data.has(target_layer):
		return

	var target_move: float = float(data[target_layer])
	var host_move: float = 0.0
	if not host_layer.is_empty() and data.has(host_layer):
		host_move = float(data[host_layer])

	var shift_x: float = (target_move - host_move) * offset_scale + offset_x
	_parent.position = Vector2(_base_parent_pos.x + shift_x, _base_parent_pos.y)


## 运行时改初始基准（例如关卡载入后重设父节点位置）
func reset_base_position() -> void:
	if _parent:
		_base_parent_pos = _parent.position


## 运行时切换目标层
func set_target_layer(layer_name: String) -> void:
	target_layer = layer_name
