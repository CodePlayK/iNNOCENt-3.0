extends BaseDataFileCollector
class_name WorldDataController

##自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	save_data_config.key = obj.obj_name
	
##配置要写入存档的数据
func custom_data():
	save_data_config.data["current_cutscene"] = CutsceneState.current_cutscene
	save_data_config.data["current_level"] = LevelState.current_level
	
##载入存档文件数据,假如数据中缺失current_level时,默认载入[member levelState.LEVELS.LEVEL_0]
func load_custom_data(data:Dictionary):
	if data and data.has("current_level"):
		EventBus._player_load_save_file_pos(data["current_level"])
		LevelState.clear_level_waiting_to_load()	
		EventBus._change_level(data["current_level"],self)
	else:
		EventBus._player_load_save_file_pos(LevelState.LEVELS.LEVEL_0)
		LevelState.clear_level_waiting_to_load()
		EventBus._change_level(LevelState.LEVELS.LEVEL_0,self)
	if data and data.has("current_cutscene"):
		CutsceneState.current_cutscene= data["current_cutscene"]
	LevelState.current_save_id = save_data_config.save_id
