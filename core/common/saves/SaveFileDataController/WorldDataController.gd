extends BaseDataFileCollector
#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	

func on_ready():
	pass
	#EventBus._load_save_file()

func custom_key():
	save_data_config.key = obj.obj_name
	
#配置要写入存档的数据
func custom_data():
	save_data_config.data["current_cutscene"] = CutsceneState.current_cutscene
	save_data_config.data["current_level"] = LevelState.current_level
	
#载入存档数据
func load_custom_data(data:Dictionary):
	if data and data["current_level"]:
		reset_level_waiting_2_load_dic()	
		EventBus._change_level(data["current_level"])
	else:
		reset_level_waiting_2_load_dic()
		EventBus._change_level(LevelState.LEVELS.LEVEL_0)
	CutsceneState.current_cutscene= data["current_cutscene"]
	LevelState.current_save_id = save_data_config.save_id

func reset_level_waiting_2_load_dic():
	for k in LevelState.level_waiting_2_load_dic:
		LevelState.level_waiting_2_load_dic[k]=true
