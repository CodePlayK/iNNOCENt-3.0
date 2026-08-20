@icon("res://core/common/resource/icon/FiniteStateMachine.svg")
extends Node
## Player 有限状态机管理器
## 负责：状态注册、切换、公共输入、攻击监听器
class_name StateManager

@export_category("配置")
@export var starting_state: BaseState
@export var base_state: BaseState
@export var common_inputing: bool = false
@export var input2current_state: bool = false
@export var listener_input: bool = false
@export var state2stating: bool = false
@export var print_state_change_log: bool = true

@onready var player: Player = get_parent()
@onready var anime: Anime = player.anime
@onready var listener: AttackListener = $AttackListener
@onready var stamina_config: StaminaConfig = PlayerState.player_stamina_config

var current_state: BaseState
var is_changing_state: bool = false
var attack_reset: bool = true

func _ready() -> void:
	EventBus.player_control_lock.connect(_on_player_control_lock)
	# 注册所有子状态
	for state in get_children():
		if state is BaseState:
			init_var(state)
			state.state_manager = self
			state.player = player
			state.anime = anime
	# 把 base_state 的引用灌给每个状态
	if base_state:
		for state in get_children():
			if state is BaseState:
				for prop in state.get_property_list():
					if prop.name.ends_with("_state") and prop.name != "base_state":
						var v = base_state.get(prop.name)
						if v:
							state.set(prop.name, v)
	change_state(starting_state)

func init_var(state) -> void:
	if not state.is_normal_state:
		PlayerState.player_unnormal_state.push_back(state)
	var a = state.get_anime_config()
	if a:
		anime.animes.append(a)

func input(event: InputEvent) -> void:
	# 0. 仅交互模式：禁止玩法输入时，只把 interact 交给当前状态
	if PlayerState.is_interact_only_mode():
		if event.is_action_pressed("interact") or event.is_action("interact"):
			if current_state:
				var interact_state = current_state.input(event)
				if interact_state:
					change_state(interact_state)
		return

	# 1. 攻击连招监听器优先拦截
	if listener.enable:
		if listener.input(event):
			if listener_input:
				Debug.dprintinfo(DebugCT.dp("[StateManager]input进入监听,且收到true", self))
			return

	# 2. 公共输入（不依赖当前状态就能触发的动作）
	var common_input = input_common_state(event)
	if common_input:
		change_state(common_input)
		return

	# 3. 交给当前状态处理
	var new_state
	if current_state:
		if input2current_state:
			Debug.dprintinfo(DebugCT.dp("[StateManager]input进入%s" % current_state.name, self))
		new_state = current_state.input(event)
	if new_state:
		change_state(new_state)

func change_state(new_state: BaseState) -> BaseState:
	if (current_state != null and new_state != null
			and (current_state != new_state or new_state is StackingState)
			and new_state.common_pre_enter()
			and new_state.pre_enter()):

		print_state_change(current_state.name, new_state.name)

		if not new_state is StackingState:
			is_changing_state = true
			current_state.exit(new_state)
			current_state.common_exit()
			PlayerState.last2_state = PlayerState.last_state
			PlayerState.last_state = current_state
			current_state = new_state
			current_state.load_var()
			current_state.play_animation()
			# color etc omitted for brevity in this recovery - FULL VERSION NEEDED
			current_state.common_enter()
			var enter_ret = current_state.enter()
			is_changing_state = false
			if enter_ret:
				return change_state(enter_ret)
	return current_state

func _on_player_control_lock(state) -> void:
	if state:
		change_state(base_state.lock_state)
	else:
		change_state(base_state.idle_state)

func input_common_state(event: InputEvent):
	if not PlayerState.can_use_gameplay_input():
		return null
	if (attack_reset
			and event.is_action_pressed("attack")
			and PlayerState.can_attack()
			and not [base_state.behitDamaged_state].has(current_state)):
		if stamina_config.current_stamina - base_state.attack0_state.stamina_cost > 0:
			if common_inputing:
				Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[attack0]", self))
			return base_state.attack0_state
		else:
			state2state(current_state.staminaerror_state, current_state)
	if event.is_action_pressed("light"):
		return base_state.light_state
	if event.is_action_pressed("dense") and PlayerState.denseable_flag:
		return base_state.dense_state
	if event.is_action_pressed("dash"):
		if stamina_config.current_stamina - base_state.dash_state.stamina_cost > 0:
			return base_state.dash_state
		else:
			state2state(current_state.staminaerror_state, current_state)
	return null

func state2state(state, from_state) -> void:
	if state2stating:
		Debug.dprintinfo(DebugCT.dp("[StateManager]state2state from %s to %s" % [from_state, state], self))
	change_state(state)

func print_state_change(from_name: String, to_name: String) -> void:
	if print_state_change_log:
		Debug.dprintinfo(DebugCT.dp("[StateManager] %s -> %s" % [from_name, to_name], self))

func physics_process(delta: float) -> void:
	if current_state and not is_changing_state:
		var ns = current_state.physics_process(delta)
		if ns:
			change_state(ns)
		var ans = current_state.after_physics_process(delta)
		if ans:
			change_state(ans)
