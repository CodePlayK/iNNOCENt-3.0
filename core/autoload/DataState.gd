extends Node
## 存档中枢：缓存组装、就绪统计、SQLite 落库与存档元数据管理

const DB_NAME := "user://data/save_data"
const SAVE_SCREENSHOT_PATH := "user://data/screen shot/"
const TABLE := "save"
const TRASH_TABLE := "trash"
const DATA := "data"
const GROUP_ID := "group_id"
const LEVEL_ID := "level_id"
const SAVE_ID := "save_id"

const parallax_move_data_source_path := "res://core/common/parallax/parallax_move_data.tres"

var ui_save_config = ResourceLoader.load(
	"res://core/common/ui/state_box/setting/save_menu_ui_save_file_config.tres"
)

## 存档的 group 类型
enum GROUP {
	WORLD = -1, ## 世界
	PLAYER = 0, ## 玩家
	NPC = 1, ## npc
	PARALLAX = 2, ## 视差层
	OBJ = 3, ## 物体
	ITEM = 4, ## 交互物体
	SAVE = 5, ## 存档
	DIALOGUE_HIS = 6, ## 对白历史
}

var db: SQLite
## 存档数据缓存 [save_id][group][level_id][key] -> data
var save_cache: Dictionary = {}
## 要存档的物体注册字典 key -> 是否已就绪
var save_obj_state: Dictionary = {}
## 存档菜单 Collector
var ui_save_data_controller: BaseDataCollector
## 存档配置类
var save_file_config: SaveDataConfig
## 当前屏幕截图
var current_screenshot: Texture2D
## 当前的存档 id
var current_save_id: int = 0:
	set(i):
		current_save_id = i
		EventBus._save_file_id_update()
## 当前的最大存档 id
var current_max_save_id: int = 0
## 当前在界面中选中的存档 id
var current_select_save_id: int = 0
## 当前存档文件数据
var current_save_file_dic: Dictionary = {}





func init_db(path) -> void:
	db = SQLite.new()
	DataState.db.path = path
	db.path = DB_NAME
	db.verbosity_level = SQLite.QUIET
	db.open_db()


# region 存档文件字典 / 截图

## 添加到存档文件字典
func add2save_file_dic(key, v) -> void:
	current_save_file_dic[key] = v
	update_max_save_id()


## 更新最大存档 id
func update_max_save_id() -> void:
	current_max_save_id = 0
	for k in current_save_file_dic.keys():
		current_max_save_id = max(current_max_save_id, int(k))


## 更新存档 id 对应的截图资源
func update_screenshot(save_id: int) -> void:
	if not DirAccess.dir_exists_absolute(SAVE_SCREENSHOT_PATH):
		DirAccess.make_dir_absolute(SAVE_SCREENSHOT_PATH)
	ResourceSaver.save(
		current_screenshot,
		SAVE_SCREENSHOT_PATH + str(save_id) + ".res"
	)


## 从资源中读取截图
func get_screenshot(save_id: int):
	return ResourceLoader.load(SAVE_SCREENSHOT_PATH + str(save_id) + ".res")

# endregion


# region 就绪锁

## 将 obj 注册到应存档字典中
func obj_save_state_init(key: String) -> void:
	save_obj_state[key] = false


## 从应存档字典中移除（关卡卸载时调用，避免永远挡落库）
func obj_save_state_remove(key: String) -> void:
	save_obj_state.erase(key)


## 重置应存档字典
func obj_save_state_reset() -> void:
	for k in save_obj_state.keys():
		save_obj_state[k] = false
	save_cache.clear()


## 将应存档字典中的所有锁设为真，并清空缓存
func obj_save_state_enable_all() -> void:
	for k in save_obj_state.keys():
		save_obj_state[k] = true
	save_cache.clear()


## 将指定对象标记为已就绪；全部就绪后执行 save_all
func obj_save_state_ready(key: String) -> void:
	save_obj_state[key] = true
	for k in save_obj_state.keys():
		if not save_obj_state[k]:
			return
	save_all()

# endregion


# region 缓存与落库

## 将存档数据配置写入缓存
## 唯一键约束：[save_id][group][level_id][key] -> data
func add2cache(sc: SaveDataConfig) -> void:
	if not sc:
		return
	if sc.group == GROUP.PLAYER:
		pass
	var entry: SaveDataConfig = sc.duplicate()
	entry.level_id = sc.level_id

	if not save_cache.has(entry.save_id):
		save_cache[entry.save_id] = {}
	if not save_cache[entry.save_id].has(entry.group):
		save_cache[entry.save_id][entry.group] = {}
	if not save_cache[entry.save_id][entry.group].has(entry.level_id):
		save_cache[entry.save_id][entry.group][entry.level_id] = {}

	save_cache[entry.save_id][entry.group][entry.level_id][entry.key] = entry.data


## 将缓存写入数据库
func save_all() -> void:
	if save_cache.is_empty():
		obj_save_state_reset()
		return

	db.open_db()
	var insert_list: Array = []

	for save_id in save_cache.keys():
		for group in save_cache[save_id].keys():
			for level_id in save_cache[save_id][group].keys():
				var payload: Dictionary = save_cache[save_id][group][level_id]
				_upsert_row(save_id, group, level_id, payload, insert_list)

	if not insert_list.is_empty():
		db.insert_rows(TABLE, insert_list)

	db.close_db()
	obj_save_state_reset()


## 存在则更新，否则加入待插入列表
func _upsert_row(
	save_id,
	group,
	level_id,
	payload: Dictionary,
	insert_list: Array
) -> void:
	var condition := "%s = %s and %s = %s and %s = %s" % [
		SAVE_ID, str(save_id),
		GROUP_ID, str(group),
		LEVEL_ID, str(level_id),
	]
	var ids: Array = db.select_rows(TABLE, condition, ["id"])
	var data_json := JSON.stringify(payload)

	if ids and ids[0]:
		db.update_rows(TABLE, "id = %s" % ids[0]["id"], {DATA: data_json})
	else:
		insert_list.append({
			SAVE_ID: str(save_id),
			LEVEL_ID: str(level_id),
			GROUP_ID: str(group),
			DATA: data_json,
		})

# endregion


# region 删除存档

## 删除指定存档：主表 → 回收表，并刷新当前 save_id
func delete_save(save_id: int) -> void:
	current_save_file_dic.erase(save_id)

	db.open_db()

	var rows: Array = db.select_rows(TABLE, "save_id = %s" % str(save_id), ["*"])
	for row in rows:
		db.insert_row(TRASH_TABLE, row)

	db.delete_rows(TABLE, "save_id = %s" % str(save_id))
	db.close_db()

	obj_save_state_enable_all()

	if ui_save_data_controller:
		ui_save_data_controller._pre_save_game()

	EventBus._delete_save(save_id)

	if current_save_id == save_id:
		update_max_save_id()
		current_save_id = current_max_save_id

# endregion
