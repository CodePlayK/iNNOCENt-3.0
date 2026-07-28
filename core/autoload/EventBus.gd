extends Node
##game
signal save_game
signal load_game
signal delete_save
signal save_id_update
##vfx
signal fallen_from_top
##cutscene
signal cutscene_camera
signal cutscene_camera_reset
signal screen_shake
signal enable_player_camera
signal cutscene_finished
signal cutscene_is_playing
signal play_cutscene_aniplayer
signal play_screen_effect
signal player_waked
##camera
signal camera_shake
##level
signal change_level
signal level_tree_exited
signal transition_show
##player
signal player_health_update
signal player_stamina_update
signal get_player_position
signal change_player_position
signal change_player_visiable
signal player_face_left
signal player_control_lock
signal player_on_fighting_changed
signal player_health_damaged
signal player_health_healed
signal player_stamina_damaged
signal player_stamina_recovered
signal player_face_changed
##sound
signal play_SE_LOOP
signal play_SE
signal play_BGM
##obj
signal obj_set_face_left
signal npc_behithard
signal move_2_vec2

func _player_on_fighting_changed(flag:bool=false):
	player_on_fighting_changed.emit(flag)
func _player_stamina_damaged():
	player_stamina_damaged.emit()
func _player_stamina_recovered():
	player_stamina_recovered.emit()
func _play_SE_LOOP(SE_LOOP_name,state=true,speed=1.0,effect_volume=0.0):
	play_SE_LOOP.emit(SE_LOOP_name,state,speed,effect_volume)
func _play_SE(SE_name,speed=1.0,effect_volume=0.0,owner_name:String="NA",state:bool = true):
	play_SE.emit(SE_name,speed,effect_volume,owner_name,state)
func _play_BGM(BGM_name,state=true,speed=1.0,effect_volume=0.0):
	play_BGM.emit(BGM_name,state,speed,effect_volume)	
func _level_tree_exited():
	level_tree_exited.emit()
func _transition_show(transition_type):
	transition_show.emit(transition_type)
func _load_game():
	load_game.emit()
func _save_game():
	save_game.emit()	
func _delete_save(save_id):
	delete_save.emit(save_id)
func _cutscene_camera(dic_markers:Dictionary):
	cutscene_camera.emit(dic_markers)
func _cutscene_camera_reset():
	cutscene_camera_reset.emit()
func _fallen_from_top(obj:String,obj_count:int):
	fallen_from_top.emit(obj,obj_count)
func _player_face_changed():
	player_face_changed.emit()
func _obj_set_face_left(name,left_flag:bool):
	obj_set_face_left.emit(name,left_flag)
func _npc_behithard(obj):
	npc_behithard.emit(obj)
func _move_2_vec2(name:String,pos:Vector2,time:float=1):
	move_2_vec2.emit(name,pos,time)
func _camera_shake(strength:float,SHAKE_DECAY:float):
	camera_shake.emit(strength,SHAKE_DECAY)

func _player_health_damaged():
	player_health_damaged.emit()
func _player_health_healed():
	player_health_healed.emit()
func _player_health_update():
	player_health_update.emit()
func _player_stamina_update():
	player_stamina_update.emit()
func _save_id_update():
	save_id_update.emit()
func _play_cutscene_aniplayer(animation_name:String):
	play_cutscene_aniplayer.emit(animation_name)
func _play_screen_effect(e_name:String,args:Array = []):
	play_screen_effect.emit(e_name,args)
func _player_waked():
	player_waked.emit()
