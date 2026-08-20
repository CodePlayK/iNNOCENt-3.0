@icon("res://core/common/resource/icon/FiniteStateMachine.svg")
extends Node
## [必须挂在 Player 节点下] 玩家有限状态机（FSM）
## 负责：收集所有状态、切换状态、转发输入/物理帧、处理受击
class_name PlayerStateManager

## 状态机启动时进入的起始状态节点
@export var starting_node: Node
## 玩家生命值配置
@export var health_config: HealthConfig
## 玩家耐力配置
@export var stamina_config: StaminaConfig

@export_group("Debug")
## 打印状态切换日志
@export var changing_state: bool
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

@onready var player: Player = $".."
@onready var starting_state: BaseState = starting_node
@onready var test_label = %TestLabel
@onready var base_state: BaseState = $base
@onready var listener: Node = $AttackListener
@onready var anime: Anime = $"../Animations/Anime"

var attack_reset: bool = true
var current_state: BaseState
var current_damage: float = 0
var all_states: Array
## 节点名 -> 状态。叶子与分组都登记，change_state 会拒绝分组。
var states: Dictionary = {}
var is_changing_state: bool = false


func init(p_player: Player) -> void:
	anime.animes.clear()
	EventBus.player_control_lock.connect(_on_player_control_lock)

	_collect_states(self)

	for state: BaseState in all_states:
		state.player = p_player
		state.health_config = health_config
		state.stamina_config = stamina_config
		state.state_manager = self
		state.anime = anime
		state.init(all_states)
		state.init_var()
		_register_state(state)

	PlayerState.player_state_history.push_back(get_state("idle"))
	anime.import()
	change_state(starting_state)


func _collect_states(node: Node) -> void:
	for child in node.get_children():
		if child is BaseState:
			all_states.append(child)
			states[String(child.name)] = child
		_collect_states(child)


func _register_state(state: BaseState) -> void:
	if state.is_group:
		return
	if not state.is_normal_state:
		PlayerState.player_unnormal_state.push_back(state)
	var cfg = state.get_anime_config()
	if cfg:
		anime.animes.append(cfg)


func get_state(state_name: String) -> BaseState:
	if state_name.is_empty():
		return null
	if states.has(state_name):
		return states[state_name]
	for key in states:
		if String(key).begins_with(state_name):
			return states[key]
	return null


func input(event: InputEvent) -> void:
	if listener.enable:
		if listener.input(event):
			if listener_input:
				Debug.dprintinfo(DebugCT.dp("[StateManager]input进入监听,且收到true", self))
			return

	var common_input = input_common_state(event)
	if common_input:
		change_state(common_input)
		return

	if current_state == null:
		return
	if input2current_state:
		Debug.dprintinfo(DebugCT.dp("[StateManager]input进入%s" % current_state.name, self))
	var new_state = current_state.input(event)
	if new_state:
		change_state(new_state)


func change_state(new_state: BaseState) -> BaseState:
	if new_state == null or new_state.is_group:
		return null
	if current_state == new_state and not new_state is StackingState:
		return null
	if not new_state.common_pre_enter() or not new_state.pre_enter():
		return null

	var from_name := current_state.name if current_state else "null"
	print_state_change(from_name, new_state.name)

	if not new_state is StackingState:
		is_changing_state = true
		if current_state:
			current_state.exit(new_state)
			current_state.common_exit()
			PlayerState.last2_state = PlayerState.last_state
			PlayerState.last_state = current_state
		current_state = new_state
		PlayerState.current_state = current_state

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
		return temp_state
	return null


func physics_process(delta: float) -> void:
	if not is_instance_valid(player) or current_state == null:
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
	var actual_string := "「Player」状态机切换: [%s] --> [%s]" % [a, b]
	if changing_state:
		Debug.dprintinfo(DebugCT.dp(actual_string, self))
	if test_label:
		test_label.text = "[%s]->[%s]" % [a, b]
	return actual_string


func _on_player_tree_exiting() -> void:
	change_state(get_state("idle"))


func _on_player_control_lock(state) -> void:
	if state:
		change_state(get_state("lock"))
	else:
		change_state(get_state("idle"))


func input_common_state(event: InputEvent):
	if PlayerState.player_control_lock:
		return null

	if (
		attack_reset
		and event.is_action_pressed("attack")
		and current_state != get_state("behitDamaged")
	):
		var attack0 := get_state("attack0")
		if stamina_config.current_stamina - attack0.stamina_cost > 0:
			if common_inputing:
				Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[attack0]", self))
			return attack0
		state2state(get_state("staminaerror"), current_state)

	if event.is_action_pressed("light"):
		if common_inputing:
			Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[light_state]", self))
		return get_state("light")

	if event.is_action_pressed("dense") and PlayerState.denseable_flag:
		if common_inputing:
			Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[dense_state]", self))
		return get_state("dense")

	if event.is_action_pressed("dash"):
		var dash := get_state("dash")
		if stamina_config.current_stamina - dash.stamina_cost > 0:
			if common_inputing:
				Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[dash_state]", self))
			return dash
		if common_inputing:
			Debug.dprinterr(DebugCT.dp("[StateManager][input_common_state]切换到[dash_state]", self))
		state2state(get_state("staminaerror"), current_state)

	return null


func state2state(state, from_state) -> void:
	if state2stating and from_state:
		Debug.dprintinfo(DebugCT.dp(
			"[StateManager][%s]主动切换状态->[%s]" % [from_state.name, state.name], self))
	change_state(state)


func string2state(state_name: String, obj) -> void:
	if state2stating:
		Debug.dprintinfo(DebugCT.dp(
			"[NpcsStateManager][%s]主动切换状态->[%s]" % [obj.name, state_name], self))
	change_state(get_state(state_name))


func get_state_by_name(state_name) -> BaseState:
	return get_state(str(state_name) if state_name else "")


func check_current_state_by_name(state_name) -> bool:
	return current_state == get_state_by_name(state_name)


func on_hurt(obj: HitBox) -> void:
	if not obj.enable:
		return

	PlayerState.player_be_hitting = true
	current_damage = obj.damage

	if current_state and current_state.anime_config:
		for bati in current_state.anime_config.bati_config:
			PlayerState.set_player_bating(bati.bating, self)
			if bati.bating:
				if on_hurt2state:
					Debug.dprintwarn(DebugCT.dp(
						"[StateManager][input_common_state]切换到[behitbati_state]", self))
				state2state(get_state("behitbati"), current_state)
				return

	if not PlayerState.dense_flag and not PlayerState.dense_success_flag:
		if on_hurt2state:
			Debug.dprintwarn(DebugCT.dp(
				"[StateManager][input_common_state]切换到[behitDamaged_state]", self))
		change_state(get_state("behitDamaged"))
