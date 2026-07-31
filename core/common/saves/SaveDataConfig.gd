extends Resource
class_name SaveDataConfig
##目标类型
@export var group:DataState.GROUP
##group下的唯一key
@export var key:String
##存档id
@export var save_id:int = 0
##所属的关卡
@export var level_id:LevelState.LEVELS = LevelState.LEVELS.LEVEL_CURRENT
var inited:bool=false
##数据
@export var data:Dictionary

func _init() -> void:
	if level_id!= LevelState.LEVELS.LEVEL_ALL:
		level_id=LevelState.current_level
	resource_local_to_scene=true
