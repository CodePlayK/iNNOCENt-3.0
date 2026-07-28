extends BaseDataCollector
##初始化事件
func on_ready():
	pass
	
##自订key	
func custom_key():
	pass
	
##配置要写入存档的数据
func custom_data():
	save_data_config.data = {"dialogue_title_dic":Dialogue.dialogue_title_dic,"dialogue_title_dic_tmp":Dialogue.dialogue_title_dic_tmp}
	
##载入存档数据
func load_custom_data(data:Dictionary):
	Dialogue.dialogue_title_dic = data["dialogue_title_dic"]
	Dialogue.dialogue_title_dic_tmp = data["dialogue_title_dic_tmp"]
	
##删除存档事件
func on_delete_save():
	pass
