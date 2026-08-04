extends MarginContainer
class_name UIMenuTab

#region Node References
@onready var save: UISettingItem = $HBoxContainer/MarginContainer/VBoxContainer/save
@onready var load: UISettingItem = $HBoxContainer/MarginContainer/VBoxContainer/load
@onready var delete: UISettingItem = $HBoxContainer/MarginContainer/VBoxContainer/delete
@onready var new_save_file_but: UISettingItem = %NewSaveFile
@onready var save_list: VBoxContainer = %SaveList
@onready var screenshot: TextureRect = %Screenshot
@onready var scroll_container: ScrollContainer = $HBoxContainer/MarginContainer2/VBoxContainer/MarginContainer/ScrollContainer
#endregion
@onready var timer: Timer = %Timer
var save_locker:bool = false
@export var debug: bool = false

var current_selected_save_file_item: UISaveFileItem


func _ready() -> void:
	save.selected.connect(on_save)
	load.selected.connect(on_load)
	delete.selected.connect(on_delete)
	new_save_file_but.selected.connect(on_new_save_file)


#region Button Callbacks
func on_save() -> void:
	if not _has_valid_selection():
		_debug_err("未选中存档!")
		return

	_set_current_save_from_selection()
	_debug_info("保存按钮按下")
	EventBus._save_game()
	EventBus._save_file_id_update()
	move_selected2top()


func on_load() -> void:
	if save_locker:return
	if not _has_valid_selection():
		_debug_err("未选中存档!")
		return
	_set_current_save_from_selection()
	_debug_info("载入按钮按下")
	EventBus._load_save_file()
	#EventBus._level_changed(LevelState.last_level, LevelState.current_level)
	move_selected2top()
	timer.start()
	save_locker=true
	
func on_delete() -> void:
	if not _has_valid_selection():
		_debug_err("未选中存档!")
		return

	var delete_id: int = DataState.current_select_save_id
	_debug_info("删除按钮按下")
	DataState.delete_save(delete_id)

	# 清除本地引用，避免悬空
	if is_instance_valid(current_selected_save_file_item) \
			and current_selected_save_file_item.save_file_item_config \
			and current_selected_save_file_item.save_file_item_config.save_id == delete_id:
		current_selected_save_file_item = null
		screenshot.texture = null

	# 尝试选中剩余的第一个存档（如果有）
	_try_select_first_remaining()


func on_new_save_file() -> void:
	if save_locker:return
	_debug_info("新建存档按下")
	DataState.current_save_id = DataState.current_max_save_id + 1
	var new_item := new_save_file(
		DataState.current_save_id,
		LevelState.current_level,
		"存档",
		Time.get_datetime_string_from_system()
	)
	current_selected_save_file_item = new_item
	EventBus._save_game()
	EventBus._save_file_id_update()
	move_selected2top()
	timer.start()
	save_locker=true

#endregion


#region Selection & List Management
## 存档文件被选中时
func on_save_file_item_selected(save_file: UISaveFileItem) -> void:
	if not is_instance_valid(save_file) or not save_file.save_file_item_config:
		return

	screenshot.texture = save_file.save_file_item_config.screen_shot
	DataState.current_select_save_id = save_file.save_file_item_config.save_id
	current_selected_save_file_item = save_file


## 新建存档文件并添加到列表
func new_save_file(save_id: int, level_id: LevelState.LEVELS, save_name: String, time: String) -> UISaveFileItem:
	var sc := UISaveFileItemConfig.new()
	DataState.add2save_file_dic(save_id, sc)

	sc.level = level_id
	sc.save_id = save_id
	sc.save_name = save_name
	sc.save_time = time

	var screenshot_path := DataState.SAVE_SCREENSHOT_PATH + str(save_id) + ".res"
	if not FileAccess.file_exists(screenshot_path):
		DataState.update_screenshot(save_id)
		sc.screen_shot = DataState.current_screenshot
	else:
		sc.screen_shot = DataState.get_screenshot(save_id)

	var item: UISaveFileItem = UiState.SAVE_FILE_ITEM.instantiate()
	save_list.add_child(item)
	item.selected.connect(on_save_file_item_selected)
	item.init(sc)
	return item


## 将当前选中的存档移动到列表顶部并滚动到顶部
func move_selected2top() -> void:
	if not is_instance_valid(current_selected_save_file_item):
		return
	if current_selected_save_file_item.get_parent() != save_list:
		return

	save_list.move_child(current_selected_save_file_item, 0)
	scroll_container.scroll_vertical = 0
#endregion


#region Helpers
func _has_valid_selection() -> bool:
	return DataState.current_save_file_dic.has(DataState.current_select_save_id) \
		and DataState.current_save_file_dic[DataState.current_select_save_id] != null


func _set_current_save_from_selection() -> void:
	var config: UISaveFileItemConfig = DataState.current_save_file_dic[DataState.current_select_save_id]
	DataState.current_save_id = config.save_id


func _try_select_first_remaining() -> void:
	for child in save_list.get_children():
		if child is UISaveFileItem and is_instance_valid(child) and child.visible:
			on_save_file_item_selected(child)
			move_selected2top()
			return
	# 没有剩余存档
	current_selected_save_file_item = null
	screenshot.texture = null
	DataState.current_select_save_id = -1


func _debug_info(msg: String) -> void:
	if debug:
		Debug.dprintinfo(DebugCT.dp(msg, self))


func _debug_err(msg: String) -> void:
	if debug:
		Debug.dprinterr(DebugCT.dp(msg, self))
#endregion


func _on_timer_timeout() -> void:
	save_locker=false
	pass # Replace with function body.
