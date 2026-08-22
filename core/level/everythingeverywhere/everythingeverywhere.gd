@icon ("res://addons/at-icons/animation/institutional_building.svg")

extends Node2D
## 简短概述：42 is here
##
## 详细描述：游戏的根目录，用于管理关卡加载

## CUTSCENER主场景路径
const CUTSCENER_PATH := "res://addons/Cutscener/main/main.tscn"
## 默认的存档资源路径
const SRC_PATH := "res://core/data/save_data.db"
## sqlite数据库位置
const DES_PATH := "user://data/save_data.db"
## 存档目录
const SAVE_PATH := "user://data"

## 关卡目录结构 [level_id] -> 场景路径
var dic_level_path: Dictionary = {}
## 已解析的 PackedScene 缓存 [path] -> PackedScene
## 第一次切换卡顿主要来自同步 load().instantiate()；缓存 PackedScene 后只剩 instantiate
var packed_level_cache: Dictionary = {}
var _threaded_requested: Dictionary = {}

@export var obj_name: String
@onready var player_camera: Camera2DPlus = %PlayerCamera
@onready var player_camera_aniplayer: AnimationPlayer = $Setting/PlayerCamera/PlayerCameraAniplayer
@onready var back_ground_color: TextureRect = $CanvasBackground/BackGroundColor
@onready var door_locked_time: Timer = $Setting/DoorLockedTime
@onready var test_mark: Node2D = %TestMark
@onready var player_player: Player = %PlayerPlayer


func _init() -> void:
	EventBus.change_level.connect(_on_change_level)
	

## 初始化
## 如果要运行 cutscener，则在这里修改：载入 cutscener 配置目录，判断当前运行是否为 cutscener
func _ready() -> void:
	Global.test_mark = test_mark
	PlayerState.player_player = player_player
	_ensure_default_save_file()
	_init_level_paths()
	Global.back_ground_color = back_ground_color
	# 后台线程预请求所有关卡 PackedScene，避免第一次过门时同步解析大 tscn
	_request_all_levels_threaded()

	# 载入 cutscener 配置目录，判断当前运行是否为 cutscener
	# var config = load_json(CutscenerGlobal.CONFIG_DATA_FILE_PATH)
	# if config["run_type"] == 0:
	# 	EventBus._load_save_file()
## 初始化关卡路径表
func _init_level_paths() -> void:
	dic_level_path[LevelState.LEVELS.LEVEL_0] = LevelState.LEVEL_0_PATH
	dic_level_path[LevelState.LEVELS.LEVEL_1] = LevelState.LEVEL_1_PATH
	dic_level_path[LevelState.LEVELS.LEVEL_2] = LevelState.LEVEL_2_PATH


func _request_all_levels_threaded() -> void:
	for path in dic_level_path.values():
		_request_level_threaded(path)


func _request_level_threaded(path: String) -> void:
	if path.is_empty() or packed_level_cache.has(path) or _threaded_requested.has(path):
		return
	if ResourceLoader.has_cached(path):
		packed_level_cache[path] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
		return
	var err := ResourceLoader.load_threaded_request(path, "", true)
	if err == OK:
		_threaded_requested[path] = true
	else:
		Debug.dprintwarn(DebugCT.dp("线程预加载失败[%s] err=%s，后续同步回退" % [path, err], self))


func _await_packed_scene(path: String) -> PackedScene:
	if packed_level_cache.has(path) and packed_level_cache[path]:
		return packed_level_cache[path]
	if ResourceLoader.has_cached(path):
		var cached := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
		packed_level_cache[path] = cached
		return cached
	if not _threaded_requested.has(path):
		_request_level_threaded(path)
	var status := ResourceLoader.load_threaded_get_status(path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(path) as PackedScene
		packed_level_cache[path] = packed
		_threaded_requested.erase(path)
		return packed
	Debug.dprintwarn(DebugCT.dp("线程加载未就绪[%s] status=%s，改用同步 load" % [path, status], self))
	var fallback := load(path) as PackedScene
	packed_level_cache[path] = fallback
	return fallback


## 载入关卡
## 第一次载入关卡时才要调用，[member LevelState.level_dic] 在此初始化，也会重置玩家相机[br]
## [member LevelState.level_waiting_2_load_dic] 载入后该关卡的待载入状态为 false
func load_level(level_path: String) -> void:
	var packed: PackedScene = await _await_packed_scene(level_path)
	var level: Levels = packed.instantiate()
	add_child.call_deferred(level)
	await level.tree_entered
	move_child(level, 0)
	await level.ready
	LevelState.current_level = level.level_id
	LevelState.level_dic[level.level_id] = level
	player_player.reparent(level.player_layer)
	LevelState.current_level_node = level
	var new_level_pos =  level.get_level_shape_pos()
	var new_level_size = level.get_level_shape_size()
	Global.player_camera.limit_left = new_level_pos.x-new_level_size.x*0.5
	Global.player_camera.limit_right =new_level_pos.x+new_level_size.x*0.5
	
	await level.resume()
	# 当前关已就绪后继续吸收其他关的 PackedScene
	_request_all_levels_threaded()

	
## 恢复已加载的关卡
func resume_level(level_id: LevelState.LEVELS) -> void:

	var level: Levels = LevelState.level_dic[level_id]
	player_player.reparent(level.player_layer)
	LevelState.current_level_node = level
	level.resume()


func _on_change_level(level_id: LevelState.LEVELS) -> void:
	door_locked_time.stop()
	LevelState.set_doors_locked(true,self)
	LevelState.playing_transition = true
	PlayerState.set_player_control_lock(true,self)
	LevelState.last_level = LevelState.current_level
	LevelState.current_level = level_id

	EventBus._test_layer_visiable(false)
	#先暂停当前level
	if LevelState.current_level_node:
		await LevelState.current_level_node.pause()
	
	if LevelState.level_dic.has(level_id):
		#假如当前关卡已经载入过执行resume
		await resume_level(level_id)
	else:
		#否则执行载入
		await load_level(dic_level_path[level_id])
	#检查关卡是否载入,载入了就执行关卡切换动画, 否[整个游戏的第一次载入]则直接把背景设置
	if LevelState.level_dic.has(LevelState.last_level) and LevelState.level_dic.has(level_id):
		await trans_play(LevelState.last_level,LevelState.current_level)
	else :
		back_ground_color.modulate = LevelState.level_dic[level_id].level_background_color
	Debug.dprintinfo(DebugCT.dp("房间切换:[%s]-->[%s]" % [str(LevelState.last_level), str(LevelState.current_level)],	self))
	PlayerState.preset_player(self)
	EventBus._level_changed(LevelState.last_level, LevelState.current_level,self)
	Global.player_camera.node_to_follow = player_player
	LevelState.level_dic[LevelState.current_level].position.y=0
	PlayerState.set_player_control_lock(false,self)
	door_locked_time.start()
	LevelState.playing_transition = false

	
func trans_play(old_level_id:LevelState.LEVELS,new_level_id:LevelState.LEVELS):
	if old_level_id==new_level_id:return
	var old_level:Levels = LevelState.level_dic[old_level_id]
	var new_level:Levels = LevelState.level_dic[new_level_id]
	var old_level_size =  old_level.get_level_shape_size()
	var old_level_pos =  old_level.get_level_shape_pos()
	var new_level_pos =  new_level.get_level_shape_pos()
	var new_level_size =  new_level.get_level_shape_size()
	var tw=create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	if LevelState.current_trans_direct==LevelState.TRANS_DIRCTS.UP:
		Debug.dprintinfo(DebugCT.dp("******开始播放关卡切换动画[UP][老关卡玩家位置:%s],[老关卡位置:%s],[玩家出生位置:%s],[相机位置:%s]" %[PlayerState.player_exit_level_pos,old_level.global_position,PlayerState.current_player_born_position,Global.player_camera.global_position],self))
		var new_level_start_x = PlayerState.player_exit_level_pos.x-PlayerState.current_player_born_position.x 
		var new_level_start_y = old_level_pos.y-old_level_size.y*0.5-(new_level_pos.y-old_level.global_position.y+new_level_size.y*0.5)
		var new_level_end_x = new_level_start_x
		var new_level_end_y = 0
		
		Global.player_camera.limit_left = min(Global.player_camera.limit_left,new_level_pos.x-new_level_size.x*0.5)
		Global.player_camera.limit_right = max(Global.player_camera.limit_right,new_level_pos.x+new_level_size.x*0.5)
		Global.player_camera.node_to_follow = null		
		var old_level_start_x = old_level.global_position.x
		var old_level_start_y = old_level.global_position.y
		var old_level_end_x = old_level.global_position.x
		var old_level_end_y = abs(new_level_end_y-new_level_start_y)
		new_level.parallax.parallax_on = true		
		Global.player_camera.position_smoothing_enabled = false
		var camera_last_pos = Global.player_camera.global_position
		player_player.reparent(new_level.player_layer)
		player_player.position = PlayerState.current_player_born_position
		new_level.global_position = Vector2(0,new_level_start_y)
		old_level.global_position.x =  -new_level_start_x
		Global.player_camera.global_position = camera_last_pos-Vector2(new_level_start_x,0)

		#用一帧让相机和两个关卡按新关卡的坐标移动到零点
		await get_tree().process_frame
		#Debug.dprintinfo(DebugCT.dp("--------开始播放切换关卡动画---------",self))
		tw.tween_property(old_level,"global_position",Vector2(old_level.global_position.x,old_level_end_y),3)	
		tw.parallel().tween_property(new_level,"global_position",Vector2(0,0),3)	
		tw.parallel().tween_property(back_ground_color,"modulate",new_level.level_background_color,3)
		await tw.finished
		new_level.parallax.parallax_on = true		
		#Debug.dprintinfo(DebugCT.dp("--------结束切换关卡动画---------",self))
		#动画过程中必须关闭smooth否则会飘移
		Global.player_camera.position_smoothing_enabled = true
		tw.kill()
		LevelState.level_dic[LevelState.last_level].position=Vector2i(0,9999)
		Global.player_camera.limit_left = new_level_pos.x-new_level_size.x*0.5
		Global.player_camera.limit_right = new_level_pos.x+new_level_size.x*0.5
		LevelState.level_dic[LevelState.last_level].hide()
	Debug.dprintinfo(DebugCT.dp("******关卡切换动画结束[UP]",self))


## 检查是否有存档，没有则从默认资源复制一份到 user 目录
func _ensure_default_save_file() -> void:
	DirAccess.make_dir_absolute(SAVE_PATH)

	if FileAccess.file_exists(DES_PATH) and !FileAccess.open(DES_PATH, FileAccess.READ).get_length() == 0:
		Debug.dprintinfo(DebugCT.dp("目标文件已存在！[%s]" % DES_PATH, self))
		DataState.init_db(DES_PATH)
		return

	var src_file := FileAccess.open(SRC_PATH, FileAccess.READ)
	if not src_file:
		Debug.dprinterr(DebugCT.dp("源文件打开失败！ [%s]" % SRC_PATH, self))
		return

	var des_file := FileAccess.open(DES_PATH, FileAccess.WRITE)
	if not des_file:
		Debug.dprinterr(DebugCT.dp("目标文件创建失败！ [%s]" % DES_PATH, self))
		src_file.close()
		return

	des_file.store_buffer(src_file.get_buffer(src_file.get_length()))
	src_file.close()
	des_file.close()
	Debug.dprintinfo(DebugCT.dp("存档数据不存在，新建数据库在User目录下！[%s]" % DES_PATH, self))
	DataState.init_db(DES_PATH)



## 读取并解析 JSON 文件，失败返回空字典
func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		Debug.dprinterr(DebugCT.dp("执行器打开json失败![%s]" % path, self))
		return {}

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		Debug.dprinterr(DebugCT.dp("执行器载入json数据失败![%s]" % error, self))
		return {}

	return json.data as Dictionary


func _on_door_locked_time_timeout() -> void:
	LevelState.set_doors_locked(false,self)
