extends Node
## 配置单一对象存档数据的父类，只负责数据组装与属性赋值。[br]
## [b]挂载要求：[/b] 必须挂在目标储存对象相关节点下，且有且仅有一个 [BaseSaver] 子节点。
class_name BaseDataCollector

signal save

## 存档模版配置
@export var save_data_config: SaveDataConfig
## 是否有 Master 连接
@export var has_master: bool = true
## 是否启用保存
@export var enable_save: bool = true
## 是否启用载入
@export var enable_load: bool = true
## 是否 debug
@export var debug: bool = false
## 是否在 ready 自动载入
@export var load_on_ready: bool = false
## 是否写入 save_id
@export var save_id: bool = true
## 是否写入 obj_id
@export var save_obj_id: bool = true
## 是否储存 position
@export var save_position: bool = true
## 是否储存朝向
@export var save_faced: bool = true
@export var log_level: SQLite.VerbosityLevel = SQLite.QUIET

## 被存档的目标对象
var obj
## 子节点 Saver
var saver: BaseSaver
## 在 DataState 中注册用的唯一键
var state_key: String


func _ready() -> void:
	if not has_master:
		on_master_ready()
		if load_on_ready and saver:
			owner.ready.connect(saver._load_game)


## Master 就绪后完成初始化（也可由外部 Master 调用）
func on_master_ready(master: Node = null) -> void:
	_resolve_obj(master)
	custom_key()
	_setup_saver()
	_connect_signals()
	_register_save_state()

	if load_on_ready and has_master and saver:
		saver._load_game()

	on_ready()


## 子类重写：初始化完成后的额外逻辑
func on_ready() -> void:
	pass


func _resolve_obj(master: Node = null) -> void:
	if master:
		obj = master.obj
	else:
		obj = get_parent().get_parent()


func _setup_saver() -> void:
	saver = _find_saver()
	if not saver:
		push_error("%s: 未找到 BaseSaver 子节点" % name)
		return
	saver.save_data_config = save_data_config
	saver.load_save.connect(_load_save)


func _find_saver() -> BaseSaver:
	for child in get_children():
		if child is BaseSaver:
			return child
	return null


func _connect_signals() -> void:
	if not EventBus.save_game.is_connected(_pre_save_game):
		EventBus.save_game.connect(_pre_save_game)
	if not EventBus.delete_save.is_connected(_on_delete_save):
		EventBus.delete_save.connect(_on_delete_save)


func _register_save_state() -> void:
	state_key = str(get_instance_id())
	DataState.obj_save_state_init(state_key)
	if debug:
		Debug.dprint(DebugCT.dp("「初始化」存档|%s" % state_key, saver))


## 前置保存游戏
func _pre_save_game() -> void:
	if not enable_save:
		return
	common_save_data()
	custom_data()
	save.emit()


## 载入存档
func _load_save(data: Dictionary) -> void:
	if not enable_load:
		return
	_apply_common_load_data(data)
	load_custom_data(data)


func _apply_common_load_data(data: Dictionary) -> void:
	if not obj:
		return
	if !data:return
	if save_position and data.has("position_x") and data.has("position_y"):
		obj.position = Vector2(data["position_x"], data["position_y"])
	if save_faced and data.has("face_left"):
		obj.face_direction.set_faced(data["face_left"])
	if !data.has("state"):return
	if data["state"]=="death":
		obj.state_manager.string2state(data["state"],self)
		if UiState.character_box_dic.has(obj.obj_name):
			UiState.set_character_box_showing(obj.character_box_config,false,self)
		else :
			UiState.set_character_box_dic(obj.character_box_config.character_box_id,obj.character_box_config,self)
			UiState.set_character_box_showing(obj.character_box_config,false,self)
	else:
		obj.state_manager.string2state("birth",self)
		if UiState.character_box_dic.has(obj.obj_name):
			UiState.set_character_box_showing(obj.character_box_config,true,self)
		else :
			UiState.set_character_box_dic(obj.character_box_config.character_box_id,obj.character_box_config,self)
			UiState.set_character_box_showing(obj.character_box_config,true,self)

## 子类重写：组装自定义存档数据
func custom_data() -> void:
	pass


## 子类重写：配置存档 key
func custom_key() -> void:
	pass


## 子类重写：载入自定义数据
func load_custom_data(data: Dictionary) -> void:
	pass


func _on_delete_save(deleted_save_id: int) -> void:
	if save_data_config and save_data_config.save_id == deleted_save_id:
		on_delete_save()


## 子类重写：当前存档被删除时的处理
func on_delete_save() -> void:
	pass


## 写入通用存档字段
func common_save_data() -> void:
	if not save_data_config:
		return

	if save_id:
		save_data_config.save_id = DataState.current_save_id

	if save_data_config.level_id == LevelState.LEVELS.LEVEL_CURRENT:
		save_data_config.level_id = LevelState.current_level

	if not obj:
		return

	if save_position:
		save_data_config.data["position_x"] = obj.position.x
		save_data_config.data["position_y"] = obj.position.y

	if save_faced:
		save_data_config.data["face_left"] = obj.face_left

	if save_obj_id:
		save_data_config.data["obj_id"] = obj.obj_name


## 存档查询条件（载入时使用）
func get_condition_save() -> String:
	var level_id: int = save_data_config.level_id
	if level_id == LevelState.LEVELS.LEVEL_CURRENT:
		level_id = LevelState.current_level
	return "level_id = %s and group_id = %s and save_id = %s" % [
		level_id,
		save_data_config.group,
		DataState.current_save_id,
	]
