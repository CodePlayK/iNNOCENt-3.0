@icon("res://core/common/resource/icon/FiniteStateMachine.svg")
extends Node
## [必须挂在 Npcs 节点下] NPC 有限状态机
class_name NpcStateManager

## 是否启用状态机（关闭则 init 后不会切入 starting1 状态）
@export var enable: bool = true
## 状态机启动时进入的起始状态节点
@export var starting_node: Node

@export_group("Debug")
## 状态机调试 UI 节点（用于可视化当前状态）
@export var npcstatemachine_ui: Node
## 打印状态切换日志
@export var changing_state: bool
## 打印伤害结算日志
@export var d_damage: bool
## 打印通用输入转发日志
@export var common_inputing: bool
## 打印“输入交给当前状态”日志
@export var input2current_state: bool
## 打印受击后切状态日志
@export var on_hurt2state: bool
## 打印 state2state 调用日志
@export var state2stating: bool
## 打印攻击监听器收到输入的日志
@export var listener_input: bool
## 打印切入受击状态的日志
@export var behit_input: bool
## 打印切入重受击/弹反状态的日志
@export var behithard_input: bool
## 打印切入死亡状态的日志
@export var death_input: bool
## 打印切入出生状态的日志
@export var birth_input: bool
## 打印切入闪避状态的日志
@export var dodge_input: bool
## 打印切入锁定状态的日志
@export var lock_input: bool

@onready var npc: Npcs = $".."
@onready var starting_state: NpcsBaseState = starting_node
@onready var test_label = get_node_or_null("%TestLabel")
@onready var base_state: NpcsBaseState = $base
@onready var anime: Anime = $"../Animations/Anime"
@onready var attack_listener: Node = get_node_or_null("Listener/AttackListener")

var running_state: NpcsBaseState
var start_state: NpcsBaseState
var start1_state: NpcsBaseState
## 重置攻击到 attack0
var attack_reset: bool = true
var current_damage: float = 0
var animation_speed: float = 1
var all_states: Array
## 节点名 -> 状态（含分组）
var states: Dictionary = {}
var is_changing_state: bool = false
## NPC 状态历史
var npc_state_history: Array = []
## 战斗状态历史
var npc_combat_state_history: Array = []
## 不允许回退的状态
var npc_unnormal_state: Array = []
var npc_combat_state: Array = []

var current_state: NpcsBaseState:
	set(state):
		current_state = state
		_push_history(npc_state_history, state)
		if state and state.is_combat_state:
			_push_history(npc_combat_state_history, state)


func _push_history(history: Array, state) -> void:
	if state == null:
		return
	if not history.is_empty() and state == history.back():
		return
	history.push_back(state)
	if history.size() > 50:
		history.pop_front()


func on_master_ready(master) -> void:
	npc = master.obj
	anime.animes.clear()
	_connect_event(EventBus.player_control_lock, _on_npc_control_lock)
	_connect_event(EventBus.npc_following_player, on_npc_following_player)
	_collect_states(self)
	for state: NpcsBaseState in all_states:
		state.npc = npc
		state.state_manager = self
		state.anime = anime
		state.init(all_states)
		state.init_var()
		_register_state(state)
	current_state = start_state
	if base_state and base_state.idle_state:
		npc_state_history.push_back(base_state.idle_state)
	anime.import()
	if npcstatemachine_ui:
		npcstatemachine_ui.init(self)
	if enable:
		change_state(start1_state)


func _connect_event(sig: Signal, cb: Callable) -> void:
	if not sig.is_connected(cb):
		sig.connect(cb)


func on_running_obj() -> void:
	if not enable:
		return
	npc.show()
	change_state(running_state)


func _collect_states(node: Node) -> void:
	for child in node.get_children():
		if child is NpcsBaseState:
			all_states.append(child)
			states[String(child.name)] = child
			if npc.running_state == child.name:
				running_state = child
			if npc.starting_state == child.name:
				start_state = child
			if npc.starting1_state == child.name:
				start1_state = child
		_collect_states(child)


func _register_state(state: NpcsBaseState) -> void:
	if state.is_group:
		return
	if not state.is_normal_state:
		npc_unnormal_state.push_back(state)
	if state.is_combat_state:
		npc_combat_state.push_back(state)
	var cfg = state.get_anime_config()
	if cfg:
		anime.animes.append(cfg)


func load_var(new_state: NpcsBaseState) -> void:
	npc.on_combat = new_state.on_combat
	npc.on_fighting = new_state.on_fighting
	animation_speed = new_state.anime_config.speed_scale if new_state.anime_config else 1.0
	npc.enable_player_detection(new_state.enable_player_detection)
	npc.enable_self(new_state.enable_self)
	npc.interaction.set_enable(new_state.interact2player)
	if new_state.player_interact_lock:
		PlayerState.add_player_lock_interact_obj(npc)
	else:
		PlayerState.remove_player_lock_interact_obj(npc)


func input(event: InputEvent) -> void:
	if attack_listener and attack_listener.enable:
		if attack_listener.input(event):
			if listener_input:
				Debug.dprintinfo(DebugCT.dp("[NpcsStateManager]input进入监听,且收到true", self))
			return
	if current_state == null:
		return
	if input2current_state:
		Debug.dprintinfo(DebugCT.dp("[NpcsStateManager]input进入%s" % current_state.name, self))
	var new_state = current_state.input(event)
	if new_state:
		change_state(new_state)


func change_state(new_state: NpcsBaseState) -> void:
	if new_state == null or new_state.is_group:
		return
	if current_state == new_state and not new_state is NpcsStackingState:
		return
	if not new_state.common_pre_enter() or not new_state.pre_enter():
		return
	print_state_change(current_state.name if current_state else "null", new_state.name)
	if not new_state is NpcsStackingState:
		is_changing_state = true
		if current_state:
			current_state.exit(new_state)
			current_state.common_exit()
		current_state = new_state
	load_var(new_state)
	new_state.load_var()
	new_state.play_animation()
	new_state.change_animation_color(
		new_state.change_sprite_color,
		new_state.pause_on_change_sprite_color
	)
	is_changing_state = false
	new_state.common_enter()
	var temp_state = await new_state.enter()
	if temp_state:
		change_state(temp_state)


func physics_process(delta: float) -> void:
	if npc == null or current_state == null:
		return
	var new_state = current_state.pre_physics_process(delta)
	if new_state:
		change_state(new_state)
		return
	if is_changing_state:
		return
	new_state = current_state.physics_process(delta)
	var after_state = current_state.after_physics_process(delta)
	if after_state:
		change_state(after_state)
	elif new_state:
		change_state(new_state)


func process(delta: float) -> void:
	if current_state == null:
		return
	var new_state = current_state.process(delta)
	if new_state and not is_changing_state:
		change_state(new_state)


func print_state_change(a, b) -> String:
	var actual_string := "「Npcs」状态机切换: [%s] --> [%s]" % [a, b]
	if changing_state:
		Debug.dprintinfo(DebugCT.dp(actual_string, self))
	if test_label:
		test_label.text = "[%s]->[%s]" % [a, b]
	return actual_string


func _on_npc_tree_exiting() -> void:
	if base_state and base_state.idle_state:
		change_state(base_state.idle_state)


func _on_npc_control_lock(locked) -> void:
	if locked:
		if base_state and base_state.talk_state:
			change_state(base_state.talk_state)
	else:
		if base_state and base_state.idle_state:
			change_state(base_state.idle_state)


func state2state(state, from_state) -> void:
	if state == null:
		return
	if state2stating and from_state:
		Debug.dprintinfo(DebugCT.dp(
			"[NpcsStateManager][%s]主动切换状态->[%s]" % [from_state.name, state.name], self))
	change_state(state)


func string2state(state_name: String, obj) -> void:
	if state2stating and obj:
		Debug.dprintinfo(DebugCT.dp(
			"[NpcsStateManager][%s]主动切换状态->[%s]" % [obj.name, state_name], self))
	change_state(get_state_by_name(state_name))


func on_hurt(obj: HitBox) -> void:
	if obj == null or not obj.enable:
		return
	npc.data.npc_be_hitting = true
	current_damage = obj.damage
	if npc.bating:
		Debug.dprintwarn(DebugCT.dp("[%s][触发霸体保护时间]" % npc.obj_name, self))
		state2state(base_state.behitbati_state, current_state)
		return
	if current_state and current_state.anime_config:
		for bati in current_state.anime_config.bati_config:
			if bati.bating:
				Debug.dprintwarn(DebugCT.dp("[%s][触发霸体保护]" % npc.obj_name, self))
				if on_hurt2state:
					Debug.dprintwarn(DebugCT.dp("[NpcsStateManager][on_hurt]切换到[behitbati_state]", self))
				state2state(base_state.behitbati_state, current_state)
				return
	var immune := [
		base_state.dodge_state,
		base_state.lock_state,
		base_state.birth_state,
		base_state.death_state,
		base_state.behithard_state,
	]
	if current_state in immune:
		return
	if current_state and current_state.on_combat:
		if d_damage:
			Debug.dprintwarn(DebugCT.dp("[NpcStateManager]受到伤害:%s" % current_damage, self))
		change_state(base_state.behit_state)


func get_last_normal_state():
	for i in range(npc_state_history.size() - 2, -1, -1):
		var state = npc_state_history[i]
		if state and not state.is_group and not npc_unnormal_state.has(state):
			return state
	return base_state.idle_state if base_state else null


func get_state_by_name(state_name) -> NpcsBaseState:
	if not state_name:
		return null
	var key := str(state_name)
	if states.has(key) and not states[key].is_group:
		return states[key]
	for n in states:
		var state: NpcsBaseState = states[n]
		if state.is_group:
			continue
		if str(n).begins_with(key):
			return state
	return null


func on_npc_following_player(p_name: String, flag: bool) -> void:
	if npc.npc_name != p_name:
		return
	await Dialogue.end_dialogue
	if flag:
		change_state(base_state.follow_state)
	else:
		npc.on_following = false
		change_state(base_state.idle_state)
