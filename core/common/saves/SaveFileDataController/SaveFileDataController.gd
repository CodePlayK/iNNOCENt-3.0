extends BaseDataFileCollector
@onready var menu: UIMenuTab = $".."

func on_ready():
	DataState.ui_save_data_controller = self

#配置要写入存档的数据
func custom_data():
	save_data_config.data.clear()
	save_data_config.data["current_save_id"] = DataState.current_save_id
	save_data_config.data["save_files"] = {}
	for k in DataState.current_save_file_dic.keys():
		if null==DataState.current_save_file_dic[k]:
			continue
		var sc:UISaveFileItemConfig = DataState.current_save_file_dic[k]
		save_data_config.data["save_files"][k] = {"save_name":sc.save_name,"save_time":sc.save_time,"level_id":sc.level}
#载入存档数据
func load_custom_data(data:Dictionary,update_current_save_id:bool):
	if update_current_save_id and data.has("current_save_id"):
		DataState.current_save_id = data["current_save_id"]
	for n in menu.save_list.get_children():
		n.hide()
		n.queue_free()
	DataState.current_save_file_dic.clear()
	for k in data["save_files"].keys():
		menu.new_save_file(int(k),data["save_files"][k]["level_id"],data["save_files"][k]["save_name"],data["save_files"][k]["save_time"])
	DataState.current_select_save_id = DataState.current_save_id
	EventBus.load_level.emit()
	menu.move_selected2top()
