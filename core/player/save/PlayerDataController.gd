extends BaseDataCollector
var load_target_level:LevelState.LEVELS
## 子类重写：初始化完成后的额外逻辑
func on_ready() -> void:
	EventBus.player_load_save_file_pos.connect(on_load_save_file)
	pass
#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	pass
#配置要写入存档的数据
func custom_data():
	save_data_config["current_level"] = LevelState.current_level
	
#载入存档数据
func load_custom_data(data:Dictionary):
	if !data:return
	if data and  data.has("position_x") and data.has("position_y"):
		if data.has("current_level"):
			if data["current_level"] == load_target_level:
				PlayerState.set_current_player_born_position(Vector2(data["position_x"], data["position_y"]),self)

func on_load_save_file(level_id):
	load_target_level = level_id
