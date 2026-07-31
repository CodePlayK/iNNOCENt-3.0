extends MarginContainer
class_name UIMenuTab
@onready var save: UISettingItem = $HBoxContainer/MarginContainer/VBoxContainer/save
@onready var load: UISettingItem = $HBoxContainer/MarginContainer/VBoxContainer/load
@onready var new_save_file_but: UISettingItem = %NewSaveFile
@onready var save_list: VBoxContainer = %SaveList
@onready var screenshot: TextureRect = %Screenshot
@onready var scroll_container: ScrollContainer = $HBoxContainer/MarginContainer2/VBoxContainer/MarginContainer/ScrollContainer
@onready var delete: UISettingItem = $HBoxContainer/MarginContainer/VBoxContainer/delete
@export var debug:bool = false
var current_selected_save_file_item:UISaveFileItem

func _ready() -> void:
	save.selected.connect(on_save)
	load.selected.connect(on_load)
	delete.selected.connect(on_delete)
	new_save_file_but.selected.connect(on_new_save_file)

func on_save():
	if !DataState.current_save_file_dic.has(DataState.current_select_save_id):
		if debug:Debug.dprinterr(DebugCT.dp("未选中存档!",self))
		return
	DataState.current_save_id = DataState.current_save_file_dic[DataState.current_select_save_id].save_id
	if debug:Debug.dprintinfo(DebugCT.dp("保存按钮按下",self))
	EventBus._save_game()
	EventBus._save_id_update()
	move_selected2top()

func on_load():
	if !DataState.current_save_file_dic.has(DataState.current_select_save_id):
		if debug:Debug.dprinterr(DebugCT.dp("未选中存档!"))
		return
	DataState.current_save_id = DataState.current_save_file_dic[DataState.current_select_save_id].save_id
	if debug:Debug.dprintinfo(DebugCT.dp("载入按钮按下",self))
	LevelState.loading_save()
	EventBus._load_game()
	move_selected2top()
	
func on_delete():
	if !DataState.current_save_file_dic.has(DataState.current_select_save_id):
		if debug:Debug.dprinterr(DebugCT.dp("未选中存档!"))
		return
	DataState.delete_save(DataState.current_select_save_id)
	if debug:Debug.dprintinfo(DebugCT.dp("删除按钮按下",self))

func on_new_save_file():
	if debug:Debug.dprintinfo(DebugCT.dp("新建存档按下",self))
	DataState.current_save_id = DataState.current_max_save_id+1
	var s = new_save_file(DataState.current_save_id,LevelState.current_level,"存档",Time.get_datetime_string_from_system())
	current_selected_save_file_item = s
	EventBus._save_game()
	EventBus._save_id_update()
	move_selected2top()
##当存档文件被选中时	
func on_save_file_item_selected(save_file:UISaveFileItem):
	screenshot.texture = save_file.save_file_item_config.screen_shot
	DataState.current_select_save_id = save_file.save_file_item_config.save_id
	current_selected_save_file_item = save_file
##新建存档文件	
func new_save_file(save_id,level_id,save_name,time):
	var sc = UISaveFileItemConfig.new()
	DataState.add2save_file_dic(int(save_id),sc)
	sc.level = level_id
	sc.save_id = save_id
	sc.save_name = save_name
	sc.save_time = time
	if !FileAccess.file_exists(DataState.SAVE_SCREENSHOT_PATH+str(save_id)+".res"):
		DataState.update_screenshot(save_id)
		sc.screen_shot = DataState.current_screenshot
	else :
		sc.screen_shot = DataState.get_screenshot(save_id)
	var s = UiState.SAVE_FILE_ITEM.instantiate()
	save_list.add_child(s)
	s.selected.connect(on_save_file_item_selected)
	s.init(sc)
	return s
##将当前选中的存档文件移动到第一位
func move_selected2top():
	if !current_selected_save_file_item:return
	save_list.move_child(current_selected_save_file_item,0)
	scroll_container.scroll_vertical = 0
