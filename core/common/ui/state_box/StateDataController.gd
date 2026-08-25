extends BaseDataCollector
@onready var item_list: VBoxContainer = %ItemList
@onready var state_box: UIStateBox = $".."
	
#配置要写入存档的数据
func custom_data():
	var list:Array
	for k in ItemState.current_item_dic.keys():
		save_data_config.data[k]= {DataState.DATA:{},"count":ItemState.current_item_dic[k][0]}
	pass
#载入存档数据
func load_custom_data(data:Dictionary):
	for node in item_list.get_children():
		node.hide()
		node.queue_free()
	for k in data.keys():
		state_box.load_item(int(k),data[k]["count"])
