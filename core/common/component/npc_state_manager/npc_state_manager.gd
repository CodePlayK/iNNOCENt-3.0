@icon("res://core/common/resource/icon/FiniteStateMachine.svg")
extends Node
##[必须挂在于Player下] 玩家状态机
class_name NpcStateManager
@export var enable:bool = true
@export var starting_node:Node
#region debug
@export_group("Debug")
@export var npcstatemachine_ui:Node2D
@export var changing_state:bool
@export var d_damage:bool
@export var common_inputing:bool
@export var input2current_state:bool
@export var on_hurt2state:bool
@export var state2stating:bool
@export var listener_input:bool
@export var behit_input:bool
@export var behithard_input:bool
@export var death_input:bool
@export var birth_input:bool
@export var dodge_input:bool
@export var lock_input:bool
#endregion
#region on_ready
@onready var npc: Npcs = $".."
@onready var starting_state: NpcsBaseState = starting_node
@onready var test_label=%TestLabel
@onready var base_state:NpcsBaseState=$base
@onready var anime: Anime = $"../Animations/Anime"
@onready var attack_listener: Node = $Listener/AttackListener
#endregion
var running_state:NpcsBaseState
var start_state:NpcsBaseState
var start1_state:NpcsBaseState
##重置攻击到attack0
var attack_reset:bool = true
var current_state: NpcsBaseState:
	set(state):
		current_state=state
		if !npc_state_history.is_empty() and state==npc_state_history.back():return
		npc_state_history.push_back(state)
		if npc_state_history.size()>50:
			npc_state_history.pop_front()
		if !state.is_combat_state:return
		if !npc_combat_state_history.is_empty() and state==npc_combat_state_history.back():return
		npc_combat_state_history.push_back(state)
		if npc_combat_state_history.size()>50:
			npc_combat_state_history.pop_front()
var current_damage: float = 0
var animation_speed: float = 1
var all_states: Array
var is_changing_state:bool = false
##玩家状态历史
var npc_state_history:Array=[]
##战斗状态历史
var npc_combat_state_history:Array=[]
##不允许回退的状态list
var npc_unnormal_state:Array=[]
var npc_combat_state:Array=[]

func on_master_ready(master) -> void:
	npc = master.obj
	anime.animes.clear()
	EventBus.player_control_lock.connect(_on_npc_control_lock)
	EventBus.npc_following_player.connect(on_npc_following_player)
	#Debug.dprintinfo(DebugCT.dp("[NpcStateManager][%s]载入所有state" %npc.name,self))
	get_childen_node(self)
	for state:NpcsBaseState in all_states:
		state.npc = npc
		state.state_manager=self
		state.anime=anime#将anime注入每一个状态
		state.init(all_states)#通知状态init
		state.init_var()
		init_var(state)
	current_state=start_state
	npc_state_history.push_back(base_state.idle_state)
	anime.import()##通知anime开始init
	if npcstatemachine_ui:
		npcstatemachine_ui.init(self)
	if enable:
		change_state(start1_state)
	
func on_running_obj():
	if !enable:return
	npc.show()
	change_state(running_state)
		
func init_var(state:NpcsBaseState):
	if !state.is_normal_state:#将所有非正常状态缓存
		npc_unnormal_state.push_back(state)
	if state.is_combat_state:
		npc_combat_state.push_back(state)
	var a = state.get_anime_config()
	if a:anime.animes.append(a)##将每个状态的anime配置注入到Anime中
		
func input(event: InputEvent) -> void:
	if attack_listener.enable:
		if attack_listener.input(event):
			if listener_input:Debug.dprintinfo(DebugCT.dp("[NpcsStateManager]input进入监听,且收到true",self))
			return
	var new_state
	if current_state:
		if input2current_state:Debug.dprintinfo(DebugCT.dp("[NpcsStateManager]input进入%s" %current_state.name,self))
		new_state = current_state.input(event)
	if new_state:
		change_state(new_state)

func change_state(new_state: NpcsBaseState) -> void:
	if null!=current_state and null!=new_state and (current_state!=new_state or new_state is NpcsStackingState) and new_state.common_pre_enter() and new_state.pre_enter():
		print_state_change(current_state.name,new_state.name)
		if !new_state is NpcsStackingState:
			is_changing_state = true
			current_state.exit(new_state)
			current_state.common_exit()
			current_state = new_state
		load_var(new_state)
		new_state.load_var()
		new_state.play_animation()
		new_state.change_animation_color(new_state.change_sprite_color,new_state.pause_on_change_sprite_color)
		is_changing_state = false
		new_state.common_enter()
		var temp_state= await new_state.enter()
		if temp_state:
			change_state(temp_state)
			
##载入每个状态的变量
func load_var(new_state:NpcsBaseState):
	npc.on_combat = new_state.on_combat
	npc.on_fighting = new_state.on_fighting
	if new_state.anime_config:
		animation_speed = new_state.anime_config.speed_scale
	else :
		animation_speed = 1.0
	npc.enable_player_detection(new_state.enable_player_detection)
	npc.enable_self(new_state.enable_self)
	npc.interaction.set_enable(new_state.interact2player)
	
	if new_state.player_interact_lock:
		PlayerState.add_player_lock_interact_obj(npc)
	else:
		PlayerState.remove_player_lock_interact_obj(npc)
		
func physics_process(delta: float) -> void:
	if !npc:return
	var new_state = current_state.pre_physics_process(delta)
	if !new_state and !is_changing_state:
		new_state = current_state.physics_process(delta)
		var new_state2 = current_state.after_physics_process(delta)
		if new_state2 and !is_changing_state:
			change_state(new_state2)
		else:
			if new_state:
				change_state(new_state)
	else :
		change_state(new_state)

func process(delta: float) -> void:
	var new_state = current_state.process(delta)
	if new_state and !is_changing_state:
		change_state(new_state)

func get_childen_node(node:Node):
	for child in node.get_children():
		if child is NpcsBaseState:
			all_states.append(child)
			if npc.running_state==child.name:
				running_state=child
			if npc.starting_state==child.name:
				start_state=child
			if npc.starting1_state==child.name:
				start1_state=child
		if child:
			get_childen_node(child)
			
func print_state_change(a,b):
	var format_string = "「Npcs」状态机切换: [%s] --> [%s]"
	var format_string1 = "[%s]->[%s]"
	var actual_string = format_string % [a, b]
	var actual_string1 = format_string1 % [a, b]
	test_label.text=actual_string1
	if changing_state:Debug.dprintinfo(DebugCT.dp(actual_string,self))
	return actual_string

func _on_npc_tree_exiting():
	change_state(base_state.idle_state)

func _on_npc_control_lock(state):
	if state:
		change_state(base_state.talk_state)
	else :
		change_state(base_state.idle_state)
	
func state2state(state,from_state):
	if !state:return
	if state2stating:Debug.dprintinfo(DebugCT.dp("[NpcsStateManager][%s]主动切换状态->[%s]" %[from_state.name,state.name],self))
	change_state(state)
	
func string2state(state_name:String,obj):
	if state2stating:Debug.dprintinfo(DebugCT.dp("[NpcsStateManager][%s]主动切换状态->[%s]" %[obj.name,state_name],self))
	change_state(get_state_by_name(state_name))
	
func on_hurt(obj:HitBox):
	if !obj.enable:
		return
	npc.data.npc_be_hitting=true
	current_damage = obj.damage
	if npc.bating :	
		Debug.dprintwarn(DebugCT.dp("[%s][触发霸体保护时间]" %npc.obj_name,self))
		state2state(base_state.behitbati_state,current_state)
		return
	if current_state.anime_config:
		for bati in current_state.anime_config.bati_config:
			if bati.bating:
				Debug.dprintwarn(DebugCT.dp("[%s][触发霸体保护]" %npc.obj_name,self))
				if on_hurt2state:
					Debug.dprintwarn(DebugCT.dp("[NpcsStateManager][input_common_state]切换到[behitDamaged_state]",self))
				state2state(base_state.behitbati_state,current_state)
				return
	if obj.enable and ![base_state.dodge_state,base_state.lock_state,base_state.birth_state,base_state.death_state,base_state.behithard_state].has(current_state) and current_state.on_combat:
		current_damage = obj.damage
		if d_damage:Debug.dprintwarn(DebugCT.dp("[NpcStateManager]受到伤害:%s" %current_damage,self))
		change_state(base_state.behit_state)

##获取上一个可切换状态
func get_last_normal_state():
	for i in npc_state_history.size():
		var state = npc_state_history[npc_state_history.size()-i-2]
		if !npc_unnormal_state.has(state):
			return state
##根据名字获取状态
func get_state_by_name(state_name):
	if !state_name:return null
	for state in all_states:
		if str(state.name).begins_with(state_name):
			return state
##更新npc跟踪玩家状态
func on_npc_following_player(name:String,flag:bool):
	if npc.npc_name!=name:return
	#有等到对话结束信号才执行，否则会直接隐藏对话框
	await Dialogue.end_dialogue
	if flag:
		change_state(base_state.follow_state)
	else :
		npc.on_following=false
		change_state(base_state.idle_state)
