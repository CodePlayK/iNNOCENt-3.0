extends BaseDataCollector
#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	obj.save_data_config.level_id=LevelState.current_level
	save_data_config.key = obj.obj_name
	
#配置要写入存档的数据
func custom_data():
	save_data_config.data["cs"] = obj.dialogue_config.current_res
	
#载入存档数据
func load_custom_data(data:Dictionary):
	if !data:return
	obj.dialogue_config.current_res = data["cs"]
	obj.dialogue_config.dialogue_res=DialogueState.dialogue_file_res[ data["cs"]]
	
