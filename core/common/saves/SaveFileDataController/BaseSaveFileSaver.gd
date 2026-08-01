extends Node
##[必须为SaveDataCollector节点的唯一子节点] 用于对象的存档与读档案，不负责数据组装与赋值，只负责IO交互
class_name BaseSaveFileSaver
@onready var save_data_collector:BaseDataFileCollector = $".."
signal load_save
var CONDITION_SAVE
var DB:SQLite
var save_data_config:SaveDataConfig

func _ready():
	DB=SQLite.new()
	DB.path=DataState.DB_NAME
	DB.verbosity_level = save_data_collector.log_level
	EventBus.load_save_file.connect(_load_save_file)
	save_data_collector.save.connect(_save)
##保存数据到数据库
func _save():
	DataState.add2cache(save_data_config)
	#if save_data_collector.debug:
	Debug.dprint(DebugCT.dp("「保存」存档|[%s]%s" %[save_data_config.level_id,save_data_config.data],self))
	DataState.obj_save_state_ready(save_data_collector.state_key)
		
##载入数据	
func _load():
	if !save_data_collector.enable_load:return
	DB.open_db()
	CONDITION_SAVE = save_data_collector.get_condition_save()
	var dic_list = DB.select_rows(DataState.TABLE,CONDITION_SAVE,[DataState.DATA])
	var data:Dictionary = {}
	if dic_list :
		data=JSON.parse_string(dic_list[0][DataState.DATA])[save_data_config.key]
		if save_data_collector.debug:Debug.dprint(DebugCT.dp("「载入」存档|[%s]%s" %[CONDITION_SAVE,JSON.stringify(data)],self))
	load_save.emit(data)
		
func _load_save_file():
	_load()
