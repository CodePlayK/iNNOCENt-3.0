extends BaseDataCollector
@onready var event_data: Node = $".."

##初始化事件
func on_ready():
	pass
	
##自订key	
func custom_key():
	pass
	
##配置要写入存档的数据
func custom_data():
	for k in event_data.event_data_dic.keys():
		save_data_config.data[k] = event_data.event_data_dic[k].event_value
	
##载入存档数据
func load_custom_data(data:Dictionary):
	for k in data.keys():
		var ec:EventConfig = event_data.get_event_config(int(k))
		ec.event_value = data[k]
		event_data.event_data_dic[int(k)] = ec
	
##删除存档事件
func on_delete_save():
	pass
