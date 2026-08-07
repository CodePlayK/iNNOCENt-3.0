@icon("res://core/common/resource/icon/FiniteStateMachine.svg")
extends Node
## [必须挂在 Player 节点下] 玩家有限状态机（FSM）
## 负责：收集所有状态、切换状态、转发输入/物理帧、处理受击
class_name PlayerStateManager

# ---------- 导出配置 ----------
@export var starting_node: Node					## 游戏开始时进入的状态节点
@export var health_config: HealthConfig			## 玩家生命配置（注入给每个状态）
@export var stamina_config: StaminaConfig		## 玩家体力配置（注入给每个状态）

@export_group("Debug")
@export var changing_state: bool				## 打印状态切换日志
@export var common_inputing: bool				## 打印公共输入（攻击/格挡/冲刺等）日志
@export var input2current_state: bool			## 打印输入进入当前状态的日志
@export var on_hurt2state: bool					## 打印受击切换状态的日志
@export var state2stating: bool					## 打印主动 state2state 切换的日志
@export var listener_input: bool				## 打印攻击监听器拦截输入的日志

# ---------- 节点引用 ----------
@onready var player: Player = $".."						## 父节点玩家
@onready var starting_state: BaseState = starting_node	## 起始状态
@onready var test_label = %TestLabel					## 调试用状态文字
@onready var base_state: BaseState = $base				## 状态树根节点（下面挂着所有具体状态）
@onready var listener: Node = $AttackListener			## 攻击连招监听器
@onready var anime: Anime = $"../Animations/Anime"		## 玩家动画控制器

# ---------- 运行时变量 ----------
var attack_reset: bool = true		## true 时允许公共输入切到 attack0（重置连招）
var current_state: BaseState		## 当前正在运行的状态
var current_damage: float = 0		## 本次受击伤害（给 behitDamaged 用）
var all_states: Array				## 递归收集到的全部 BaseState
var is_changing_state: bool = false	## 正在切换状态时为 true，防止物理帧重复切状态


## 初始化（由 Player._ready 调用）
## 1. 收集所有状态并注入依赖
## 2. 把每个状态的动画配置交给 Anime
## 3. 进入起始状态
func init(player: Player) -> void:
	anime.animes.clear()
	EventBus.player_control_lock.connect(_on_player_control_lock)

	# 递归把 StateManager 下所有 BaseState 收集进 all_states
	get_childen_node(self)

	for state: BaseState in all_states:
		state.player = player
		state.health_config = health_config
		state.stamina_config = stamina_config
		state.state_manager = self
		state.anime = anime					# 把动画控制器注入每个状态
		state.init(all_states)				# 让状态自己绑定其他状态引用
		state.init_var()					# 状态一次性初始化
		init_var(state)						# 本管理器对状态的额外处理

	current_state = base_state
	PlayerState.player_state_history.push_back(base_state.idle_state)
	anime.import()							# 通知 Anime 完成初始化
	change_state(starting_state)			# 进入起始状态


## 对单个状态做额外注册：
## - 非普通状态记入 PlayerState.player_unnormal_state
## - 把该状态的 AnimeConfig 加入 Anime.animes
func init_var(state) -> void:
	if not state.is_normal_state:
		PlayerState.player_unnormal_state.push_back(state)
	var a = state.get_anime_config()
	if a:
		anime.animes.append(a)


## 处理输入事件（由 Player._unhandled_input 转发过来）
## 优先级：攻击监听器 > 公共输入（攻击/格挡/冲刺/灯光）> 当前状态自己的 input
func input(event: InputEvent) -> void:
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


## 核心：切换到新状态
## 流程：
##   检查能否进入 → 旧状态 exit/common_exit → 更新 current_state
##   → 新状态 load_var / 播动画 / 改颜色 → common_enter → enter
##   如果 enter 返回了另一个状态，会继续切换
func change_state(new_state: BaseState) -> BaseState:
	if (current_state != null and new_state != null
			and (current_state != new_state or new_state is StackingState)
			and new_state.common_pre_enter()
			and new_state.pre_enter()):

		print_state_change(current_state.name, new_state.name)

		# 普通状态才走完整的退出/切换流程（StackingState 可叠加）
		if not new_state is StackingState:
			is_changing_state = true
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

		# enter 可以异步返回下一个要切的状态
		var temp_state = await new_state.enter()
		if temp_state:
			change_state(temp_state)
			return temp_state
	return null


## 物理帧（由 Player._physics_process 调用）
## 顺序：pre_physics_process → physics_process → after_physics_process
## 任一环节返回新状态就会切换
func physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var new_state = current_state.pre_physics_process(delta)
	if not new_state and not is_changing_state:
		new_state = current_state.physics_process(delta)
		var new_state2 = current_state.after_physics_process(delta)
		if new_state2 and not is_changing_state:
			change_state(new_state2)
		else:
			if new_state:
				change_state(new_state)
	else:
		change_state(new_state)


## 普通帧（由 Player._process 调用）
func process(delta: float) -> void:
	var new_state = current_state.process(delta)
	if new_state and not is_changing_state:
		change_state(new_state)


## 递归收集 node 及其子节点中所有 BaseState
func get_childen_node(node: Node) -> void:
	for child in node.get_children():
		if child is BaseState:
			all_states.append(child)
		if child:
			get_childen_node(child)


## 打印并更新调试 Label 的状态切换信息
func print_state_change(a, b) -> String:
	var format_string = "「Player」状态机切换: [%s] --> [%s]"
	var format_string1 = "[%s]->[%s]"
	var actual_string = format_string % [a, b]
	var actual_string1 = format_string1 % [a, b]
	if changing_state:
		Debug.dprintinfo(DebugCT.dp(actual_string, self))
	return actual_string


## 玩家节点退出场景树时，强制回到 idle
func _on_player_tree_exiting() -> void:
	change_state(base_state.idle_state)


## 响应 EventBus.player_control_lock
## true → 进入 lock 状态；false → 回到 idle
func _on_player_control_lock(state) -> void:
	if state:
		change_state(base_state.lock_state)
	else:
		change_state(base_state.idle_state)


## 处理不依赖当前状态的公共输入（攻击 / 灯光 / 格挡 / 冲刺）
## 返回要切换的目标状态，没有则返回 null
func input_common_state(event: InputEvent):
	if PlayerState.player_control_lock:
		return null

	# 攻击（体力足够且不在 behitDamaged）
	if (attack_reset
			and event.is_action_pressed("attack")
			and not [base_state.behitDamaged_state].has(current_state)):
		if stamina_config.current_stamina - base_state.attack0_state.stamina_cost > 0:
			if common_inputing:
				Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[attack0]", self))
			return base_state.attack0_state
		else:
			state2state(current_state.staminaerror_state, current_state)

	# 灯光
	if event.is_action_pressed("light"):
		if common_inputing:
			Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[light_state]", self))
		return base_state.light_state

	# 格挡（dense）
	if event.is_action_pressed("dense") and PlayerState.denseable_flag:
		if common_inputing:
			Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[dense_state]", self))
		return base_state.dense_state

	# 冲刺
	if event.is_action_pressed("dash"):
		if stamina_config.current_stamina - base_state.dash_state.stamina_cost > 0:
			if common_inputing:
				Debug.dprintwarn(DebugCT.dp("[StateManager][input_common_state]切换到[dash_state]", self))
			return base_state.dash_state
		else:
			if common_inputing:
				Debug.dprinterr(DebugCT.dp("[StateManager][input_common_state]切换到[dash_state]", self))
			state2state(current_state.staminaerror_state, current_state)

	return null


## 主动从 from_state 切到指定 state（带调试日志）
func state2state(state, from_state) -> void:
	if state2stating:
		Debug.dprintinfo(DebugCT.dp(
			"[StateManager][%s]主动切换状态->[%s]" % [from_state.name, state.name], self))
	change_state(state)


## 通过状态名字符串切换（主要给 NPC 等外部用）
func string2state(state_name: String, obj) -> void:
	if state2stating:
		Debug.dprintinfo(DebugCT.dp(
			"[NpcsStateManager][%s]主动切换状态->[%s]" % [obj.name, state_name], self))
	change_state(get_state_by_name(state_name))


## 根据名字（前缀匹配）查找状态
func get_state_by_name(state_name):
	if not state_name:
		return null
	for state in all_states:
		if str(state.name).begins_with(state_name):
			return state
	return null


## 检查当前状态名字是否匹配
func check_current_state_by_name(state_name) -> bool:
	return current_state == get_state_by_name(state_name)


## 玩家被 HitBox 打中时调用
## 1. 记录伤害
## 2. 若当前状态处于霸体 → 切 behitbati
## 3. 否则若不在格挡成功 → 切 behitDamaged
func on_hurt(obj: HitBox) -> void:
	if not obj.enable:
		return

	PlayerState.player_be_hitting = true
	current_damage = obj.damage

	# 检查当前动画是否有霸体配置
	if current_state.anime_config:
		for bati in current_state.anime_config.bati_config:
			PlayerState.set_player_bating(bati.bating, self)
			if bati.bating:
				if on_hurt2state:
					Debug.dprintwarn(DebugCT.dp(
						"[StateManager][input_common_state]切换到[behitDamaged_state]", self))
				state2state(base_state.behitbati_state, current_state)
				return

	# 不在格挡中且没有格挡成功 → 正常受伤
	if not PlayerState.dense_flag and not PlayerState.dense_success_flag:
		if on_hurt2state:
			Debug.dprintwarn(DebugCT.dp(
				"[StateManager][input_common_state]切换到[behitDamaged_state]", self))
		change_state(base_state.behitDamaged_state)
