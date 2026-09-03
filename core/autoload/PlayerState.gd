@tool
##玩家状态
extends Node
var player_player:Player
var player_health_config:HealthConfig
var player_stamina_config:StaminaConfig

func set_player_current_default_expression(exp:String):
	player_player.character_box_config.current_default_expression = exp

##玩家出生时朝向
var player_born_facing_left:bool = false
func set_player_born_facing_left(fl:bool,source:Node):
	player_born_facing_left = fl
	Debug.dprintinfo(DebugCT.dp("更新玩家出生面朝向左: [%s]" %[fl],source))
	
var player_exit_level_pos:Vector2
var current_player_born_position:Vector2 = Vector2(-551.0,255.0,)

func set_current_player_born_position(pos:Vector2,source:Node):
	current_player_born_position = pos
	Debug.dprintinfo(DebugCT.dp("更新玩家出生点位置: [%s]" %[pos],source))
	

##玩家操控锁
var player_control_lock:bool=false

func set_player_control_lock(flag:bool,source:Node):
	player_control_lock = flag
	Debug.dprintinfo(DebugCT.dp("更新[玩家控制锁定状态]为[%s]" %[flag],source))
	EventBus._player_control_lock(flag)
	
func get_player_control_lock(source:Node)->bool:
	#Debug.dprintinfo(DebugCT.dp("获取[玩家控制锁定状态]为[%s]" %player_control_lock,source))
	return player_control_lock
##面朝左
var face_left:bool=false:
	set(f):
		if face_left!=f:EventBus._player_face_changed()
		face_left = f
		if f:
			face_left_normalize = -1
		else :
			face_left_normalize = 1
var face_left_normalize:int=1:
	set(i):
		face_left_normalize = i
		if player_player:
			player_player.face_left_normalized = i
##面朝左
var running_left:bool=false:
	set(f):
		if running_left!=f:EventBus._player_running_changed()
		running_left = f
		if f:
			running_left_normalize = -1
		else :
			running_left_normalize = 1
var running_left_normalize:int=1:
	set(i):
		running_left_normalize = i

			
##玩家是否可以进行交互
var player_interact_being_locked:bool=false
##玩家交互锁对象{对象名,对象}
var player_lock_interact_obj:Dictionary
var player_attack_lock:Dictionary
func set_player_attack_lock(obj,flag:bool = true):
	if flag:
		player_attack_lock[obj.name] = obj
	else :
		player_attack_lock.erase(obj.name)
func is_player_attack_locked():
	return !player_attack_lock.is_empty()
##玩家在不同房间的zindex
var player_z_index={
	"Bedroom":0
}
##玩家正处于在战斗中[chase,attack]
var is_player_on_fighting:bool=false:
	set(f):
		is_player_on_fighting = f
		EventBus._player_on_fighting_changed(is_player_on_fighting)
		if player_player:
			player_player.ui.player_on_fighting_changed(f)

##正在与玩家战斗的对象{对象名,对象}
var player_on_fighting:Dictionary
##玩家状态历史
var player_state_history:Array=[]
##不允许回退的状态list
var player_unnormal_state:Array=[]
##玩家全局坐标
var player_global_position:Vector2:
	set(v2):
		player_global_position = v2
		CutsceneState.player_position = v2
var player_screen_position:Vector2
var max_height:float
var current_height:float:
	set(f):
		current_height = f
		if light_flag:
			max_height = max(max_height,f)
var start_jump_height:float
##上一个状态
var last_state:BaseState
##前二个状态
var last2_state:BaseState
##当前状态
var current_state:BaseState:
	set(state):
		current_state=state
		if state==player_state_history.back():return
		player_state_history.push_back(state)
		if player_state_history.size()>50:
			player_state_history.pop_front()
##技能锁定
var ability_lock:bool=false
##正在弹反的标记
var dense_flag:bool=false
##能够弹反的标记
var denseable_flag:bool=true
##弹反结果的标记
var dense_success_flag:bool=false
##是否正在攻击,包含多段攻击,并不代表实际hit中
var attacking:bool=false
##不包含多段攻击的冷歇,代表hit
var hitting:bool=false
##能够轻化
var lightable_flag:bool=true
var light_flag:bool=false
##正在受击
var player_be_hitting:bool=false
var double_jump_able:bool=false
var on_collection_hint:bool = false
var bating:bool = false
func set_player_bating(b:bool,source:Node):
	bating = b
	Debug.dprintinfo(DebugCT.dp("设置玩家霸体状态 - [b]",source))

##获取上一个可切换状态
func get_last_normal_state():
	for i in player_state_history.size():
		var state = player_state_history[player_state_history.size()-i-2]
		if !player_unnormal_state.has(state):
			return state
##只禁用玩家接触交互obj			
func disable_player_interactive_only():
	get_tree().call_group_flags(2,"player_interactable_only","enable_all_interact",false)
##只禁用鼠标交互obj		
func disable_mouse_interactable_only():
	get_tree().call_group_flags(2,"mouse_interactable_only","enable_all_interact",false)
##只启用玩家接触交互obj			
func enable_player_interactive_only():
	get_tree().call_group_flags(2,"player_interactable_only","enable_all_interact",true)
##只启用鼠标交互obj		
func enable_mouse_interactable_only():
	get_tree().call_group_flags(2,"mouse_interactable_only","enable_all_interact",true)	
##禁用所有交互物	
func disable_all_interactable():
	disable_mouse_interactable_only()
	disable_player_interactive_only()
##启用所有交互物
func enable_all_interactable():
	enable_player_interactive_only()
	enable_mouse_interactable_only()
##重置player	
func preset_player(source):
	ability_lock=false
	dense_flag=false
	dense_success_flag=false
	denseable_flag=true
	lightable_flag=true
	player_be_hitting=false
	attacking=false
	Debug.dprintinfo(DebugCT.dp("重置玩家状态",source))
##添加到玩家交互锁中	
func add_player_lock_interact_obj(obj):
	if player_lock_interact_obj.keys().has(obj.name):
		return
	player_lock_interact_obj[obj.name]=obj
##移除玩家交互锁	
func remove_player_lock_interact_obj(obj):
	if !player_lock_interact_obj.keys().has(obj.name):
		return
	player_lock_interact_obj.erase(obj.name)
func on_player_ready(player1:Player):
	player_player = player1
func is_player_on_floor():
	return player_player.is_on_floor()
