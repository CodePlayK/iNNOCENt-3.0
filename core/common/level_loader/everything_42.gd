extends Node2D
const LEVEL_0_PATH="res://core/level/level_0/Level0.tscn"
const CUTSCENER_PATH="res://addons/Cutscener/main/main.tscn"
var dic_room_path:Dictionary
const src_path = "res://core/data/data.tres"
const des_path = "user://data/data.db"
const save_path = "user://data"
@export var obj_name:String
func _ready():
	resfile_2_userfile(src_path,des_path)
	dic_room_path[LevelState.LEVELS.LEVEL_0]=LEVEL_0_PATH
	EventBus.change_level.connect(_on_change_level)
	var config = load_json(CutscenerGlobal.CONFIG_DATA_FILE_PATH)
	if config["run_type"] == 0:
		_on_change_level(LevelState.LEVELS.LEVEL_0)
	#_on_change_level(LevelState.LEVELS.LEVEL_0)
	#_change_rooms(Global.rooms.ROOM_1)
func load_room(room_path:String):
	var room = load(room_path).instantiate()
	get_tree().root.add_child(room)
	get_tree().current_scene=room
	
func _on_change_level(level_id):
	if dic_room_path.has(level_id):
		LevelState.last_level=LevelState.current_level
		get_tree().current_scene.queue_free()
		await get_tree().current_scene.tree_exited
		LevelState.current_level=level_id
		Debug.dprintinfo(DebugCT.dp("房间切换:["+str(LevelState.last_level)+"]-->["+str(LevelState.current_level)+"]",self))
		load_room(dic_room_path[level_id])
		PlayerState.preset_player()
		
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
