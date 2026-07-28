extends BaseDataCollector
@onready var menu: UIMenuTab = $".."
var loaded:bool = false

func on_ready():
	DataState.ui_save_data_controller = self

#配置要写入存档的数据
func custom_data():
	save_data_config.data.clear()
	for k in DataState.current_save_file_dic.keys():
		if null==DataState.current_save_file_dic[k]:
			continue
		var sc:UISaveFileItemConfig = DataState.current_save_file_dic[k]
		save_data_config.data[k] = {"save_name":sc.save_name,"save_time":sc.save_time,"level_id":sc.level}
#载入存档数据
func load_custom_data(data:Dictionary):
	if loaded:return
	loaded = true
	for n in menu.save_list.get_children():
		n.hide()
		n.queue_free()
	DataState.current_save_file_dic.clear()
	for k in data.keys():
		menu.new_save_file(k,data[k]["level_id"],data[k]["save_name"],data[k]["save_time"])
	DataState.current_save_id = DataState.current_max_save_id
	DataState.current_select_save_id = DataState.current_save_id
	EventBus._load_game()
	menu.move_selected2top()
