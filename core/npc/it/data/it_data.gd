extends BaseDataCollector
#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	save_data_config = obj.save_data_config
	
#配置要写入存档的数据
func custom_data():
	save_data_config.data["hp"] = obj.health.current_health
	
#载入存档数据
func load_custom_data(data:Dictionary):
	obj.health.current_health = data["hp"]
	obj.state_manager.string2state("idle",self)
