@tool
extends Node
var title_able:bool=true
var cutscene_playing:bool=false:
	set(f):
		if f:
			if !cutscene_playing:
				EventBus._cutscene_is_playing()
				cutscene_playing=f
		else:
			if cutscene_playing:
				EventBus._cutscene_finished()
				cutscene_playing=f
var cutscener_playing:bool
var current_cutscene:String="0_0_0"
var test_var_String:String
var test_var_Vector2:Vector2
var test_var_int:int
var test_var_float:float
var test_var_Array:Array
var test_var_Dictionary:Dictionary
var test_var_Resource:Resource
var player_position:Vector2



##修改玩家状态
func change_player_state(state_name:String):
	PlayerState.player_player.state_manager.string2state(state_name,self)
##修改玩家状态
func set_player_control_lock(flag:bool):
	PlayerState.set_player_control_lock(flag,self)
##播放过场动画	
func play_cutscene_aniplayer(animation_name:String):
	EventBus._play_cutscene_aniplayer(animation_name)
##对话
func talk(dialoge_config:DialogueConfig,title:String = ""):
	Dialogue.start(dialoge_config,title)
	await Dialogue.end_dialogue
##设置玩家位置
func set_player_pos(pos:Vector2,face_left:int = 0):
	PlayerState.player_player.global_position = pos
	match face_left:
		1:
			PlayerState.player_player.face_direction.set_faced(false)
		-1:
			PlayerState.player_player.face_direction.set_faced(true)
##设置玩家朝向
func set_player_faced(face_left:bool = false):
	PlayerState.player_player.face_direction.set_faced(face_left)
##移动到位置				
func move2pos(obj_name:String,pos:Vector2):
	EventBus._move_2_vec2(obj_name,pos)
##播放屏幕特效
func play_screen_effect(e_name:String,args:Array):
	EventBus._play_screen_effect(e_name,args)
func set_player_attack_lock(flag:bool):
	PlayerState.set_player_attack_lock(self,flag)
