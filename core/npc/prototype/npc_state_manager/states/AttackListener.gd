extends Node
@onready var timer: Timer = $Timer
@onready var state_manager: NpcStateManager = $"../.."
@export_category("Debug")
## 打印监听器收到输入的日志
@export var input_receive: bool = false
## 打印“收到输入但监听器已关闭”的日志
@export var input_receive_but_disable: bool = false
## 打印触发条件判定成功、即将切状态的日志
@export var input_receive_call_func_success: bool = false
## 打印触发条件判定失败的日志
@export var input_receive_call_func_fail: bool = false
var to_state: NpcsBaseState
var from_state: NpcsBaseState
var trigger: Callable
var enable: bool


func _ready() -> void:
	if timer and not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)


func listen_to_state(to_state1: NpcsBaseState, trigger1: Callable, time: float, from_state1: NpcsBaseState):
	to_state = to_state1
	from_state = from_state1
	trigger = trigger1
	timer.start(time)
	state_manager.attack_reset = false
	enable = true


func input(event: InputEvent) -> bool:
	if input_receive:
		Debug.dprinterr(DebugCT.dp("[监听]收到input", self))
	if not enable:
		if input_receive_but_disable:
			Debug.dprinterr(DebugCT.dp("[监听]enable=false", self))
		return false
	if trigger.call(event):
		if to_state:
			if input_receive_call_func_success:
				Debug.dprinterr(DebugCT.dp("[监听]判断成功开始切换状态", self))
			state_manager.state2state(to_state, to_state)
			enable = false
			to_state = null
			return true
		else:
			if input_receive_call_func_fail:
				Debug.dprinterr(DebugCT.dp("[监听]判断失败", self))
			state_manager.attack_reset = true
	return false


func _on_timer_timeout() -> void:
	state_manager.npc.data.attacking = false
	reset()


func reset():
	enable = false
	state_manager.attack_reset = true
	timer.stop()
	to_state = null
