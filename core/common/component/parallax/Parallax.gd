## 视差层
##
## 根据玩家的移动有规则的移动此节点下的所有一级子节点[br]
## [color=yellow]注意:必须挂载于[Rooms]节点下![br]
## 视差层速度按子节点顺序对应 parallax_layer_speed_0 ~ _8[/color][br]
## 一般将[Player],[Npcs]等其他需要移动的节点放于同一个视差速度为[param 0]的layer下
class_name Parallax
extends Component

#region Exports
## 视差层累计位移，储存于 Resource，可供其他 node 使用
@export var parallax_move_data: ParallaxMoveData
@export var parallax_on:bool = true
@export var parallax_main_layer: Node2D

@export_category("视差层速度配置")
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
var player_last_position_x: float = 0.0
var player_position_x: float = 0.0


#endregion


func init_var() -> void:
	clazz_name = "Parallax"


func ready() -> void:
	LevelState.current_main_layer = parallax_main_layer
	_rebuild_speed_array()
	get_parallax_layers()


func on_start() -> void:
	for k in parallax_move_data.dic_layers_move_data.keys():
		parallax_move_data.dic_layers_move_data[k] = 0.0

	await RenderingServer.frame_post_draw
	player_last_position_x = get_player_position_x()

	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.position_smoothing_enabled = true


func _process(delta: float) -> void:
	if !parallax_on:return
	player_position_x = get_player_position_x()
	if int(player_position_x)!=int(player_last_position_x):
		Debug.dprint(DebugCT.dp("%s -> %s" %[player_last_position_x,player_position_x],self))
	var layer_count: int = mini(parallax_layers.size(), parallax_layers_speed.size())

	for i in layer_count:
		on_parallax(parallax_layers_speed[i], parallax_layers[i], delta)

	player_last_position_x = player_position_x


func get_player_position_x() -> float:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return player_last_position_x
	return get_parent().to_local(cam.get_screen_center_position()).x


## 与原版公式数值完全等价：
## add = speed * delta * abs(dx) * 0.1，再按移动方向取符号
## 化简后：add = -speed * delta * dx * 0.1
## 再乘以 speed_scale（默认 1.0 时与原版一致）
func on_parallax(parallax_speed: float, parallax_layer: Node2D, delta: float) -> void:
	if not is_instance_valid(parallax_layer):
		return

	var dx: float = player_position_x - player_last_position_x
	if is_zero_approx(dx) or is_zero_approx(speed_scale):
		return

	var add_position_x: float = -parallax_speed * delta * dx * 0.1 * speed_scale
	if is_zero_approx(add_position_x):
		return

	parallax_move_data.dic_layers_move_data[parallax_layer.name] = \
		parallax_move_data.dic_layers_move_data.get(parallax_layer.name, 0.0) + add_position_x
	parallax_layer.position.x += add_position_x


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
