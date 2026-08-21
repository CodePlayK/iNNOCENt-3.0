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
	save_data_config.data = event_data.event_data_dic
	
##载入存档数据
func load_custom_data(data:Dictionary):
	event_data.event_data_dic = data
	
##删除存档事件
func on_delete_save():
	pass
