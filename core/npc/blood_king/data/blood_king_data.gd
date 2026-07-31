extends BaseDataCollector
#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	obj.save_data_config.level_id=LevelState.current_level
	save_data_config = obj.save_data_config
	
#配置要写入存档的数据
func custom_data():
	save_data_config.data["hp"] = obj.health.current_health
	if obj.state_manager.current_state == obj.state_manager.base_state.death_state:
		save_data_config.data["state"] = obj.state_manager.base_state.death_state.name
	else :
		save_data_config.data["state"] = "idle"
#载入存档数据
func load_custom_data(data:Dictionary):
	obj.health.current_health = data["hp"]
	if data["state"]=="death":
		obj.state_manager.string2state(data["state"],self)
	else:
		obj.state_manager.string2state("birth",self)
	
