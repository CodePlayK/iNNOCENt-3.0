##视差层
##
##根据玩家的移动有规则的移动此节点下的所有一级子节点[br]
##[color=yellow]注意:必须挂载于[Rooms]节点下![br]
##视差层速度配置必须与对应node名一致[/color][br]
##一般将[Player],[Npcs]等其他需要移动的节点放于同一个视差速度为[param 0]的layer下
class_name Parallax extends Component
#此节点下的第一代子节点会作为视差层
@export var parallax_main_layer:Node2D
@export_category("视差层速度配置")
@export var parallax_layer_speed_0:=-110
@export var parallax_layer_speed_1:=-80
@export var parallax_layer_speed_2:=-60
@export var parallax_layer_speed_3:=-40
@export var parallax_layer_speed_4:=-30
@export var parallax_layer_speed_5:=-20
@export var parallax_layer_speed_6:=0
@export var parallax_layer_speed_7:=20
@export var parallax_layer_speed_8:=200
var parallax_layers:Array=[]
var parallax_layers_speed:Array[float]=[]
var player_last_position_x:float=0.0
var player_position_x:float=0
##当前帧所增加的距离
var add_position_x=0
var dic_position:Dictionary={}
##视差层的计算起点
@onready var parallax_start=%ParallaxStart
##视差层的每一层至今所移动的距离,储存于[Resource]中,可供其他node使用
var parallax_move_data:ParallaxMoveData

func init_var():
	clazz_name="Parallax"
	
func ready():
	LevelState.current_main_layer = parallax_main_layer
	parallax_move_data=preload(DataState.parallax_move_data_source_path)
	get_parallax_layers()
	parallax_layers_speed.append(parallax_layer_speed_0)
	parallax_layers_speed.append(parallax_layer_speed_1)
	parallax_layers_speed.append(parallax_layer_speed_2)
	parallax_layers_speed.append(parallax_layer_speed_3)
	parallax_layers_speed.append(parallax_layer_speed_4)
	parallax_layers_speed.append(parallax_layer_speed_5)
	parallax_layers_speed.append(parallax_layer_speed_6)
	parallax_layers_speed.append(parallax_layer_speed_7)
	parallax_layers_speed.append(parallax_layer_speed_8)
	
func on_start():
	for k in parallax_move_data.dic_layers_move_data.keys():
		parallax_move_data.dic_layers_move_data[k] = 0
	await RenderingServer.frame_post_draw
	player_last_position_x = get_player_position_x()
	get_viewport().get_camera_2d().position_smoothing_enabled=true
	
func physics_process(delta: float):
	player_position_x=get_player_position_x()
	for i in range(0,parallax_layers.size()):
		on_parallax(parallax_layers_speed[i],parallax_layers[i],delta)
	player_last_position_x=player_position_x
	
func get_player_position_x()->float:
	return get_viewport().get_camera_2d().get_screen_center_position().x

func on_parallax(parallax_speed,parallax_layer,delta):
	add_position_x=parallax_speed*delta*(abs(player_position_x-player_last_position_x))*0.1
	if player_last_position_x>player_position_x:
		add_position_x=add_position_x
	elif player_last_position_x<player_position_x:
		add_position_x=-add_position_x
	else :
		add_position_x=0
	if  add_position_x!=0:
		parallax_move_data.dic_layers_move_data[parallax_layer.name]+=add_position_x
		parallax_layer.position.x+=add_position_x
		
func get_parallax_layers():
	parallax_move_data.dic_all_layer.clear()
	for layer in get_children():
		if  layer is ParallaxLayeri:
			parallax_layers.append(layer)
			parallax_move_data.dic_layers_move_data[layer.name]=0
			parallax_move_data.dic_all_layer.append(layer)
		
