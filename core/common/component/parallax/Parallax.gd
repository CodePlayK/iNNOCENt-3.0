## 视差层
##
## 根据玩家的移动有规则的移动此节点下的所有一级子节点[br]
## [color=yellow]注意:必须挂载于[Rooms]节点下![br]
## 视差层速度按子节点顺序对应 parallax_layer_speed_0 ~ _8[/color][br]
## 一般将[Player],[Npcs]等其他需要移动的节点放于同一个视差速度为[param 0]的layer下
## [br]
## [b]新逻辑[/b]：以 [param parallax_origin] 为 x 位移原点，
## 用玩家到该原点的距离计算各层偏移量（绝对位置驱动）。
class_name Parallax
extends Component

#region Exports
## 视差层累计位移，储存于 Resource，可供其他 node 使用
@export var parallax_move_data: ParallaxMoveData
@export var parallax_on: bool = true
@export var parallax_main_layer: Node2D
## 视差 x 位移原点。玩家到此节点的 x 距离决定各层偏移量。
## 未指定时退化为使用相机/玩家当前位置作为相对参考。
@export var parallax_origin: Node2D = $".."
@export_category("视差层速度配置")
@export var parallax_layer_speed_m6: float = -320.0
@export var parallax_layer_speed_m5: float = -280.0
@export var parallax_layer_speed_m4: float = -240.0
@export var parallax_layer_speed_m3: float = -200.0
@export var parallax_layer_speed_m2: float = -190.0
@export var parallax_layer_speed_m1: float = -150.0
@export var parallax_layer_speed_0: float = -110.0
@export var parallax_layer_speed_1: float = -80.0
@export var parallax_layer_speed_2: float = -60.0
@export var parallax_layer_speed_3: float = -40.0
@export var parallax_layer_speed_4: float = -30.0
@export var parallax_layer_speed_5: float = -20.0
@export var parallax_layer_speed_6: float = 0.0
@export var parallax_layer_speed_7: float = 100.0
@export var parallax_layer_speed_8: float = 200.0
## 全局速度缩放（1.0 = 与原版完全一致）
@export_range(-10, 10, 0.1, "or_greater") var speed_scale: float = 1.0
#endregion

#region Runtime
var parallax_layers: Array[ParallaxLayeri] = []
var parallax_layers_speed: Array[float] = []
var player_position_x: float = 0.0
#endregion

func init_var() -> void:
	clazz_name = "Parallax"

func ready() -> void:
	LevelState.current_main_layer = parallax_main_layer
	_rebuild_speed_array()
	get_parallax_layers()

func on_start() -> void:
	# 重置累计位移
	for k in parallax_move_data.dic_layers_move_data.keys():
		parallax_move_data.dic_layers_move_data[k] = 0.0

	await RenderingServer.frame_post_draw

	# 根据当前距离初始化各层位置，避免第一帧跳变
	player_position_x = get_player_position_x()
	var origin_x := _get_origin_x()
	var dist := player_position_x - origin_x
	var layer_count: int = mini(parallax_layers.size(), parallax_layers_speed.size())
	for i in layer_count:
		var layer := parallax_layers[i]
		if not is_instance_valid(layer):
			continue
		var target_x := -parallax_layers_speed[i] * dist * 0.1 * speed_scale
		parallax_move_data.dic_layers_move_data[layer.name] = target_x
		layer.position.x = target_x

	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.position_smoothing_enabled = true

func _process(_delta: float) -> void:
	if not parallax_on:
		return

	player_position_x = get_player_position_x()
	var origin_x := _get_origin_x()
	var dist := player_position_x - origin_x

	var layer_count: int = mini(parallax_layers.size(), parallax_layers_speed.size())
	for i in layer_count:
		_apply_parallax(parallax_layers_speed[i], parallax_layers[i], dist)

func get_player_position_x() -> float:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return player_position_x
	return get_parent().to_local(cam.get_screen_center_position()).x

## 获取原点的本地 x（与玩家位置同一坐标系）
func _get_origin_x() -> float:
	if is_instance_valid(parallax_origin):
		return get_parent().to_local(parallax_origin.global_position).x
	# 未指定原点时，退化为 0（相当于以当前 Rooms 本地原点为参考）
	return 0.0

## 基于「玩家到原点的距离」计算绝对偏移
## 原版增量公式化简后等价于：offset = -speed * dist * 0.1 * speed_scale
func _apply_parallax(parallax_speed: float, parallax_layer: Node2D, dist: float) -> void:
	if not is_instance_valid(parallax_layer):
		return
	if is_zero_approx(speed_scale):
		return

	var target_x: float = -parallax_speed * dist * 0.001 * speed_scale
	var current_x: float = parallax_move_data.dic_layers_move_data.get(parallax_layer.name, 0.0)

	if is_equal_approx(current_x, target_x):
		return

	parallax_move_data.dic_layers_move_data[parallax_layer.name] = target_x
	parallax_layer.position.x = target_x

func get_parallax_layers() -> void:
	parallax_layers.clear()
	parallax_move_data.dic_all_layer.clear()
	for layer in get_children():
		if layer is ParallaxLayeri:
			parallax_layers.append(layer)
			if not parallax_move_data.dic_layers_move_data.has(layer.name):
				parallax_move_data.dic_layers_move_data[layer.name] = 0.0
			parallax_move_data.dic_all_layer.append(layer)

func _rebuild_speed_array() -> void:
	parallax_layers_speed = [
		parallax_layer_speed_m6,
		parallax_layer_speed_m5,
		parallax_layer_speed_m4,
		parallax_layer_speed_m3,
		parallax_layer_speed_m2,
		parallax_layer_speed_m1,
		parallax_layer_speed_0,
		parallax_layer_speed_1,
		parallax_layer_speed_2,
		parallax_layer_speed_3,
		parallax_layer_speed_4,
		parallax_layer_speed_5,
		parallax_layer_speed_6,
		parallax_layer_speed_7,
		parallax_layer_speed_8,
	]
