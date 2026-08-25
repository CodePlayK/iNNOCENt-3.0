extends BaseDataCollector
@onready var event_data: EventData = $".."

##初始化事件
func on_ready():
	pass
	
##自订key	
func custom_key():
	pass
	
##配置要写入存档的数据
func custom_data():
	save_data_config.data["event"] = DataState.resource_to_json(event_data.events)
	
##载入存档数据
func load_custom_data(data:Dictionary):
	if data.has("event"):
		DataState.json_to_resource(data["event"],event_data.events)
	
##删除存档事件
func on_delete_save():
	pass
