extends Node2D

const EVERYTHINGEVERYWHERE_PATH="res://core/level/everythingeverywhere/everythingeverywhere.tscn"
const CUTSCENER_PATH="res://addons/Cutscener/main/main.tscn"
var dic_level_path:Dictionary
const src_path = "res://core/data/data.tres"
const des_path = "user://data/data.db"
const save_path = "user://data"
@export var obj_name:String
@onready var player_camera: Camera2DPlus = %PlayerCamera
@onready var player_camera_aniplayer: AnimationPlayer = $Setting/PlayerCamera/PlayerCameraAniplayer


func _init() -> void:
	EventBus.change_level.connect(_on_change_level)

func _ready():
	resfile_2_userfile(src_path,des_path)
	dic_level_path[LevelState.LEVELS.LEVEL_0]=LevelState.LEVEL_0_PATH
	dic_level_path[LevelState.LEVELS.LEVEL_1]=LevelState.LEVEL_1_PATH
	#载入cutscener配置目录，判断当前运行是否为cutscener
	return
	var config = load_json(CutscenerGlobal.CONFIG_DATA_FILE_PATH)
	if config["run_type"] == 0:
		_on_change_level(LevelState.current_level)
		
func load_level(level_path:String):
	var level:Levels = load(level_path).instantiate()
	add_child.call_deferred(level)
	await level.tree_entered
	move_child(level,0)
	await level.ready
	#设置玩家相机
	player_camera.node_to_follow = level.player
	player_camera_aniplayer.play("RESET")
	LevelState.current_level_node = level
	
func _on_change_level(level_id):
	if !dic_level_path.has(level_id) or LevelState.current_level==level_id:
		Debug.dprintinfo(DebugCT.dp("当前房间已载入:[%s]" %level_id,self))
		return
	if LevelState.current_level_node:
		LevelState.current_level_node.hide()
		LevelState.current_level_node.queue_free()
	LevelState.last_level=LevelState.current_level
	LevelState.current_level=level_id
	Debug.dprintinfo(DebugCT.dp("房间切换:["+str(LevelState.last_level)+"]-->["+str(LevelState.current_level)+"]",self))
	load_level(dic_level_path[level_id])
	PlayerState.preset_player()
		
#检查否有存档，没有则新建默认存档		
func resfile_2_userfile(src_path,des_path):
	DirAccess.make_dir_absolute(save_path)
	var src_file = FileAccess.open(src_path,FileAccess.READ)
	if !src_file:
		#Debug.dprinterr(DebugCT.dp("源文件打开失败！ ["+src_path+"]",self,))
		return
	if src_file.file_exists(des_path):
		#Debug.dprintinfo(DebugCT.dp("目标文件已存在！["+des_path+"]",self))
		return	
	var des_file = FileAccess.open(des_path,FileAccess.WRITE)
	var size = src_file.get_length()
	var buffer=src_file.get_buffer(size)
	des_file.store_buffer(buffer)
	Debug.dprintinfo(DebugCT.dp("存档数据不存在，新建数据库在User目录下！["+des_path+"]",self))
	src_file.close()
	des_file.close()
	
func load_json(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if OK!=error:
		Debug.dprinterr(DebugCT.dp("执行器载入json数据失败![%s]" %error,self,))
	var data_received = json.data as Dictionary
	return data_received
