extends Node
## 必须为 [BaseDataCollector] 的唯一子节点。[br]
## 负责普通对象存档与读档的 IO，不负责数据组装与属性赋值。
class_name BaseSaver

signal load_save(data: Dictionary)

@onready var save_data_collector: BaseDataCollector = get_parent() as BaseDataCollector

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
	# 普通 obj：响应 load_game（关卡 resume / 读档时通知所有 saver）
	if not EventBus.load_game.is_connected(_load_game):
		EventBus.load_game.connect(_load_game)
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
func _load() -> void:
	if not save_data_collector or not save_data_collector.enable_load:
		return
	if not save_data_config:
		load_save.emit({})
		return

	# 仅加载「全局关卡」或「当前关卡」的数据
	if not _should_load_for_current_level():
		return

	var condition := save_data_collector.get_condition_save()
	var data := _query_save_data(condition)

	if save_data_collector.debug:
		Debug.dprint(DebugCT.dp(
			"「载入」存档|[条件:%s]结果:%s" % [condition, JSON.stringify(data)],
			self
		))

	load_save.emit(data)


## 是否应在当前关卡执行载入
func _should_load_for_current_level() -> bool:
	var level_id: int = save_data_config.level_id
	return (
		level_id == LevelState.LEVELS.LEVEL_ALL
		or level_id == LevelState.current_level
	)


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


## 响应 [signal EventBus.load_game] / Collector 主动调用
func _load_game() -> void:
	_load()
