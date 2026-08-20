@tool
## 玩家全局状态（Autoload）
## 负责：跨系统的玩家控制闸门、朝向、战斗标记、状态历史等
extends Node

var player_player: Player
var player_health_config: HealthConfig
var player_stamina_config: StaminaConfig

# ---------- 位置 ----------
var player_exit_level_pos: Vector2
var current_player_born_position: Vector2 = Vector2(-551.0, 255.0)

func set_current_player_born_position(pos: Vector2, source: Node) -> void:
	current_player_born_position = pos
	Debug.dprintinfo(DebugCT.dp("更新玩家出生点位置: [%s]" % [pos], source))


# ============================================================
# 全局控制闸门（最佳实践：按 reason 叠锁，多系统互不覆盖）
# ============================================================

## 兼容旧逻辑：整体控制锁（为 true 时进入 lock 状态，并禁止玩法输入）
var player_control_lock: bool = false

## 玩法输入总开关（综合计算结果）。false 时玩家只能使用交互键。
var gameplay_input_enabled: bool = true
## 攻击总开关（综合计算）
var attack_enabled: bool = true
## 奔跑总开关（run / fastrun，综合计算）
var run_enabled: bool = true

## reason -> true；任意 reason 存在则对应能力关闭
var _gameplay_input_lock_reasons: Dictionary = {}
var _attack_disable_reasons: Dictionary = {}
var _run_disable_reasons: Dictionary = {}

## 旧版攻击锁对象表 {对象名: 对象}，仍保留
var player_attack_lock: Dictionary = {}


func set_player_control_lock(flag: bool, source: Node) -> void:
	player_control_lock = flag
	# 与玩法输入闸同步：整体锁定时禁止玩法输入
	set_gameplay_input_enabled(not flag, "player_control_lock", source)
	Debug.dprintinfo(DebugCT.dp("更新[玩家控制锁定状态]为[%s]" % [flag], source))
	EventBus._player_control_lock(flag)


## 设置是否接受玩法输入。enabled=false 时仅允许交互键。
## reason 用于叠锁，例如 "cutscene" / "dialogue" / "ui"
func set_gameplay_input_enabled(enabled: bool, reason: String = "default", source: Node = null) -> void:
	if enabled:
		_gameplay_input_lock_reasons.erase(reason)
	else:
		_gameplay_input_lock_reasons[reason] = true
	_recompute_control_flags()
	if source:
		Debug.dprintinfo(DebugCT.dp(
			"玩法输入[%s] reason=[%s] → gameplay_input_enabled=%s" % [enabled, reason, gameplay_input_enabled],
			source))


## 设置是否允许攻击
func set_attack_enabled(enabled: bool, reason: String = "default", source: Node = null) -> void:
	if enabled:
		_attack_disable_reasons.erase(reason)
	else:
		_attack_disable_reasons[reason] = true
	_recompute_control_flags()
	if source:
		Debug.dprintinfo(DebugCT.dp(
			"攻击许可[%s] reason=[%s] → attack_enabled=%s" % [enabled, reason, attack_enabled],
			source))


## 设置是否允许奔跑（run / fastrun）
func set_run_enabled(enabled: bool, reason: String = "default", source: Node = null) -> void:
	if enabled:
		_run_disable_reasons.erase(reason)
	else:
		_run_disable_reasons[reason] = true
	_recompute_control_flags()
	if source:
		Debug.dprintinfo(DebugCT.dp(
			"奔跑许可[%s] reason=[%s] → run_enabled=%s" % [enabled, reason, run_enabled],
			source))


func _recompute_control_flags() -> void:
	gameplay_input_enabled = _gameplay_input_lock_reasons.is_empty()
	attack_enabled = _attack_disable_reasons.is_empty()
	run_enabled = _run_disable_reasons.is_empty()


## 是否可使用玩法输入（移动/跳/冲刺/格挡/轻化/攻击等）
func can_use_gameplay_input() -> bool:
	return gameplay_input_enabled and not player_control_lock


## 是否仅允许交互（禁止玩法输入时）
func is_interact_only_mode() -> bool:
	return not can_use_gameplay_input()


## 是否允许攻击
func can_attack() -> bool:
	return attack_enabled and player_attack_lock.is_empty() and can_use_gameplay_input()


## 是否允许奔跑
func can_run() -> bool:
	return run_enabled and can_use_gameplay_input()


func set_player_attack_lock(obj, flag: bool = true) -> void:
	if flag:
		player_attack_lock[obj.name] = obj
	else:
		player_attack_lock.erase(obj.name)


func is_player_attack_locked() -> bool:
	return not player_attack_lock.is_empty() or not attack_enabled


# ---------- 朝向 ----------
var face_left: bool = false:
	set(f):
		if face_left != f:
			EventBus._player_face_changed()
		face_left = f
		if f:
			face_left_normalize = -1
		else:
			face_left_normalize = 1

var face_left_normalize: int = 1:
	set(i):
		face_left_normalize = i
		if player_player:
			player_player.face_left_normalized = i

var running_left: bool = false:
	set(f):
		if running_left != f:
			EventBus._player_running_changed()
		running_left = f
		if f:
			running_left_normalize = -1
		else:
			running_left_normalize = 1

var running_left_normalize: int = 1:
	set(i):
		running_left_normalize = i


# ---------- 交互 ----------
var player_interact_being_locked: bool = false
var player_lock_interact_obj: Dictionary = {}

## 玩家在不同房间的 zindex
var player_z_index = {
	"Bedroom": 0
}

## 玩家正处于在战斗中
var is_player_on_fighting: bool = false:
	set(f):
		is_player_on_fighting = f
		if player_player:
			player_player.ui.player_on_fighting_changed(f)

## 正在与玩家战斗的对象 {对象名: 对象}
var player_on_fighting: Dictionary = {}

## 玩家状态历史
var player_state_history: Array = []
## 不允许回退的状态 list
var player_unnormal_state: Array = []

var player_global_position: Vector2:
	set(v2):
		player_global_position = v2
		CutsceneState.player_position = v2

var player_screen_position: Vector2
var max_height: float
var current_height: float:
	set(f):
		current_height = f
		if light_flag:
			max_height = max(max_height, f)

var start_jump_height: float
var last_state: BaseState
var last2_state: BaseState
var current_state: BaseState:
	set(state):
		current_state = state
		if state == player_state_history.back():
			return
		player_state_history.push_back(state)
		if player_state_history.size() > 50:
			player_state_history.pop_front()

var ability_lock: bool = false
var dense_flag: bool = false
var denseable_flag: bool = true
var dense_success_flag: bool = false
var attacking: bool = false
var hitting: bool = false
var lightable_flag: bool = true
var light_flag: bool = false
var player_be_hitting: bool = false
var double_jump_able: bool = false
var on_collection_hint: bool = false
var bating: bool = false

func set_player_bating(b: bool, source: Node) -> void:
	bating = b
	Debug.dprintinfo(DebugCT.dp("设置玩家霸体状态 - [b]", source))


func get_last_normal_state():
	for i in player_state_history.size():
		var state = player_state_history[player_state_history.size() - i - 2]
		if not player_unnormal_state.has(state):
			return state


func disable_player_interactive_only() -> void:
	get_tree().call_group_flags(2, "player_interactable_only", "enable_all_interact", false)

func disable_mouse_interactable_only() -> void:
	get_tree().call_group_flags(2, "mouse_interactable_only", "enable_all_interact", false)

func enable_player_interactive_only() -> void:
	get_tree().call_group_flags(2, "player_interactable_only", "enable_all_interact", true)

func enable_mouse_interactable_only() -> void:
	get_tree().call_group_flags(2, "mouse_interactable_only", "enable_all_interact", true)

func disable_all_interactable() -> void:
	disable_mouse_interactable_only()
	disable_player_interactive_only()

func enable_all_interactable() -> void:
	enable_player_interactive_only()
	enable_mouse_interactable_only()


func preset_player(source) -> void:
	ability_lock = false
	dense_flag = false
	dense_success_flag = false
	denseable_flag = true
	lightable_flag = true
	player_be_hitting = false
	attacking = false
	_gameplay_input_lock_reasons.clear()
	_attack_disable_reasons.clear()
	_run_disable_reasons.clear()
	_recompute_control_flags()
	Debug.dprintinfo(DebugCT.dp("重置玩家状态", source))


func add_player_lock_interact_obj(obj) -> void:
	if player_lock_interact_obj.keys().has(obj.name):
		return
	player_lock_interact_obj[obj.name] = obj

func remove_player_lock_interact_obj(obj) -> void:
	if not player_lock_interact_obj.keys().has(obj.name):
		return
	player_lock_interact_obj.erase(obj.name)


func on_player_ready(player1: Player) -> void:
	player_player = player1


func is_player_on_floor() -> bool:
	return player_player.is_on_floor()
