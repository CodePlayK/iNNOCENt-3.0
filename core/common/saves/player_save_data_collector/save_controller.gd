@icon("res://addons/at-icons/mesh/floppy_disk.svg")

extends PlayerDataCollector
var load_target_level:LevelState.LEVELS
## 子类重写：初始化完成后的额外逻辑
func on_ready() -> void:
	pass
#自定义在[LEVEL_ID][GROUP][KEY]唯一键key	
func custom_key():
	pass
#配置要写入存档的数据
func custom_data():
	save_data_config.data["current_level"] = LevelState.current_level
	
#载入存档数据
func load_custom_data(data:Dictionary):
	pass
func load_load_save_file_custom_data(data:Dictionary):
	if !data.has("current_level"):return
	if data["current_level"] == load_target_level:
		PlayerState.player_exit_level_pos = PlayerState.player_player.global_position
		PlayerState.set_current_player_born_position(Vector2(data["position_x"], data["position_y"]),self)
