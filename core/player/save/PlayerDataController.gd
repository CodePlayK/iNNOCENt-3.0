extends BaseDataCollector

#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	pass
#配置要写入存档的数据
func custom_data():
	pass
	
#载入存档数据
func load_custom_data(data:Dictionary):
	if data and  data.has("position_x") and data.has("position_y"):
		PlayerState.current_player_born_position =  Vector2(data["position_x"], data["position_y"])
	pass
