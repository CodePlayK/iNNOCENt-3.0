extends Node
##[必须为SaveDataCollector节点的唯一子节点] 用于player对象的存档与读档案，不负责数据组装与赋值，只负责IO交互
class_name PlayerSaver
@onready var player = $"../.."
@onready var save_data_collector = $".."
signal load_save
const TABLE_NAME="player"
const VERBOSITY_LEVEL: int = SQLite.QUIET  
var CONDITION_SAVE
var DB:SQLite
func _ready():
	DB=SQLite.new()
	DB.path=DataState.DB_NAME
	DB.verbosity_level = VERBOSITY_LEVEL
	EventBus.load_game.connect(_load_game)
	#EventBus.delete_save.connect(_delete_save)
	save_data_collector.save.connect(_save)
	save_data_collector.preset.connect(_preset)
	await save_data_collector.ready

##初始化存档,当数据库没有记录时插入	
func _preset():
	DB.open_db()
	var dic:Dictionary
	dic["level_id"]=LevelState.current_level
	dic[DataState.DATA]=JSON.stringify(save_data_collector.dic_save_data)
	DB.insert_row(TABLE_NAME,dic)
	DB.close_db()
	Debug.dprint(DebugCT.dp("%s|player「初始化」存档|%s" %[player.name,JSON.stringify(dic)],self))
	_load()
	
##保存数据到数据库
func _save():
	DB.open_db()
	var dic:Dictionary
	dic["level_id"]=LevelState.current_level
	dic[DataState.DATA]=JSON.stringify(save_data_collector.dic_save_data)
	get_condition_save(player)
	DB.update_rows(TABLE_NAME,CONDITION_SAVE,dic)
	DB.close_db()
##载入数据	
func _load():
	if !save_data_collector.enable_load:return
	DB.open_db()
	get_condition_save(player)
	var data=JSON.parse_string(DB.select_rows(TABLE_NAME,CONDITION_SAVE,[DataState.DATA])[0][DataState.DATA])
	save_data_collector.dic_save_data=data
	#Debug.dprint(DebugCT.dp("%s|player「载入」存档|%s" %[player.name,JSON.stringify(data)],self))	
	load_save.emit()
	
func _load_game():
	_load()

func _delete_save():
	#Debug.dprint("%s|player「删除」存档|" %player.name)
	Debug.dprint(DebugCT.dp("%s|player「删除」存档|%s" %[player.name],self))		
func get_condition_save(node):
	CONDITION_SAVE="level_id="+str(LevelState.current_level)
