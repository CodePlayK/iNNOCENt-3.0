extends Node
## 必须为 [BaseDataFileCollector] 的唯一子节点。[br]
## 负责对象存档与读档的 IO，不负责数据组装与属性赋值。
class_name BaseSaveFileSaver

signal load_save(data: Dictionary,update_current_save_id:bool)

@onready var save_data_collector: BaseDataFileCollector = get_parent() as BaseDataFileCollector

var db: SQLite
var save_data_config: SaveDataConfig


func _ready() -> void:
	_init_db()
	_connect_signals()


func _init_db() -> void:
	db = SQLite.new()
	db.path = DataState.DB_NAME
	if save_data_collector:
		db.verbosity_level = save_data_collector.log_level
	else:
		db.verbosity_level = SQLite.QUIET


func _connect_signals() -> void:
	if not EventBus.load_save_file.is_connected(_load_save_file):
		EventBus.load_save_file.connect(_load_save_file)
	if save_data_collector and not save_data_collector.save.is_connected(_save):
		save_data_collector.save.connect(_save)


## 将当前配置写入 DataState 缓存，并标记本收集器已就绪
func _save() -> void:
	if not save_data_config or not save_data_collector:
		return

	DataState.add2cache(save_data_config)

	if save_data_collector.debug:
		Debug.dprint(DebugCT.dp(
			"「保存」存档|[level_id:%s]data:%s" % [save_data_config.level_id, save_data_config.data],
			self
		))

	DataState.obj_save_state_ready(save_data_collector.state_key)


## 从数据库读取当前条件对应的数据，并通过 [signal load_save] 发出
func _load(update_current_save_id) -> void:
	if not save_data_collector or not save_data_collector.enable_load:
		return
	if not save_data_config:
		load_save.emit({},update_current_save_id)
		return

	var condition := save_data_collector.get_condition_save()
	var data := _query_save_data(condition)

	if save_data_collector.debug:
		Debug.dprintwarn(DebugCT.dp(
			"「存档管理器载入」存档文件|[%s]%s" % [condition, JSON.stringify(data)],
			self
		))

	load_save.emit(data,update_current_save_id)


## 按条件查询并解析出当前 key 对应的数据字典
func _query_save_data(condition: String) -> Dictionary:
	db.open_db()
	var rows: Array = db.select_rows(DataState.TABLE, condition, [DataState.DATA])
	db.close_db()

	if rows.is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(rows[0][DataState.DATA])
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var row_data: Dictionary = parsed
	if not row_data.has(save_data_config.key):
		return {}

	var value: Variant = row_data[save_data_config.key]
	return value if typeof(value) == TYPE_DICTIONARY else {}


## 响应 [signal EventBus.load_save_file]
func _load_save_file(update_current_save_id:bool = true) -> void:
	_load(update_current_save_id)


## 供 Collector 在 master ready 后主动触发的载入入口
func _load_game() -> void:
	_load(true)
