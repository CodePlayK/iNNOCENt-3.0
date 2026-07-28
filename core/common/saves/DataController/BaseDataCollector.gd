extends Node
##[必须挂载于目标储存对象根节点,必须有单一saver子节点] 配置单一对象存档数据的父类，只负责数据组装与属性赋值
class_name BaseDataCollector
var obj
var saver:BaseSaver
signal save
@export var save_data_config:SaveDataConfig
@export var has_master:bool = true
@export var enable_save:bool = true
@export var enable_load:bool = true
@export var debug:bool = false
@export var load_on_ready:bool = false
@export var save_id:bool = true
@export var save_obj_id:bool = true
@export var save_position:bool = true
@export var save_faced:bool = true
@export var log_level:SQLite.VerbosityLevel = SQLite.QUIET
var state_key

func _ready() -> void:
	if !has_master:
		on_master_ready()
		if load_on_ready:
			owner.ready.connect(saver._load_game)

func on_master_ready(master:Node = null):
	if master:
		obj=master.obj
	else:
		obj=get_parent().get_parent()
	custom_key()
	saver=get_children()[0]
	if save_data_config.level_id == LevelState.LEVELS.LEVEL_CURRENT:
		save_data_config.level_id = LevelState.current_level
	saver.save_data_config=save_data_config
	saver.load_save.connect(_load_save)
	EventBus.save_game.connect(_pre_save_game)
	EventBus.delete_save.connect(_on_delete_save)
	if debug:Debug.dprint(DebugCT.dp("「初始化」存档|%s" %[get_instance_id()],saver))
	state_key = str(get_instance_id())
	DataState.obj_save_state_init(state_key)
	if load_on_ready and has_master:
		saver._load_game()
	on_ready()
##子类重写
func on_ready():
	pass
##前置保存游戏
func _pre_save_game():
	if !enable_save:return
	common_save_data()
	custom_data()
	save.emit()
##载入存档
func _load_save(data:Dictionary):
	if obj and save_position and !data.is_empty():
		obj.position.x=data["position_x"]
		obj.position.y=data["position_y"]
	if obj and save_faced and data.has("face_left"):
		obj.face_direction.set_faced(data["face_left"])
	load_custom_data(data)
##子类重写，用于配置要存档的数据
func custom_data():
	pass
##子类重写，用于配置要存档的key
func custom_key():
	pass
##子类重写，用于载入存档的数据
func load_custom_data(data:Dictionary):
	pass
##子类重写，用于载入存档的数据
func _on_delete_save(save_id:int):
	if save_data_config.save_id == save_id:
		on_delete_save()
func on_delete_save():
	pass
##通用存档数据
func common_save_data():
	if save_id:
		save_data_config.save_id = DataState.current_save_id
	if save_data_config.level_id == LevelState.LEVELS.LEVEL_CURRENT:
		save_data_config.level_id = LevelState.current_level
	if obj and save_position:
		save_data_config.data["position_x"]=obj.position.x
		save_data_config.data["position_y"]=obj.position.y
	if obj and save_faced:
		save_data_config.data["face_left"]=obj.face_left
	if save_obj_id:
		save_data_config.data["obj_id"]=obj.obj_name
##存档条件,只在载入时使用
func get_condition_save():
	var li
	if save_data_config.level_id == LevelState.LEVELS.LEVEL_CURRENT:
		li = LevelState.current_level
	else :
		li = save_data_config.level_id
	return "level_id = %s and group_id = %s and save_id = %s" %[li,save_data_config.group,DataState.current_save_id]
