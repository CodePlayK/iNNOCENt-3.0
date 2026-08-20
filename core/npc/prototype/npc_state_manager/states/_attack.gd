@icon("res://core/common/resource/icon/Editor3DHandle.svg")
extends NpcsBaseState
## NPC 攻击状态基类
class_name NpcsAttackState
@export_category("配置")
@export_group("伤害")
## 本段攻击命中时造成的伤害
@export var damage: float = 1.0
@export_group("基础配置")
## 连段成功后切入的下一段攻击状态；为空则连段结束
@export var next_attack: NpcsAttackState
## 未连段时回退到的状态（通常是 idle / chase）
@export var fallback_state: NpcsBaseState
## 经过攻击时长该比例后，才允许切换到下一段攻击（0~1）
@export_range(0, 1.0) var to_next_attack_threshold: float = .2
## 攻击动画结束后的硬直时间（秒）
@export_range(0, 5.0) var after_attack_stiff_time: float = .5
## 攻击后监听下一段攻击输入的窗口时长（秒）
@export_range(0, 2.0) var listen_next_attack_time: float = 1
## 攻击时播放的音效名
@export var sound_name: String = "slash7"
@export_group("运动配置")
## 攻击状态中是否允许水平移动
@export var moveable: bool = true
## 攻击状态中是否允许转身
@export var change_face_able: bool = true
## 攻击状态中是否应用重力并 move_and_slide
@export var enable_physics: bool = true
## 攻击中移动速度相对行走速度的倍率
@export_range(0, 2.0) var move_speed_scale_to_walk: float = 1.0
## 攻击用 Marker（伤害判定/特效挂点等）
@export var marker: Marker
@export_group("Debug")
## 打印收到攻击输入的日志
@export var attack_input_receive: bool = false
## 打印开始监听下一段攻击的日志
@export var start_listener: bool = false
## 打印“计时结束且切入下一段攻击”的日志
@export var timeout2attack: bool = false
## 打印“计时结束但未连段”的日志
@export var timeout_not2attack: bool = false
var tween
@onready var attack_timer: Timer = get_node_or_null("attackTimer")
var to_next_attack: bool = false
@onready var attack_time_event: Node = get_node_or_null("%BloodkingAttackTime")


func _ready() -> void:
	if attack_timer and not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)


func enter():
	if attack_time_event:
		attack_time_event.add_time()
	npc.hit_box.disable_shape()
	npc.hit_box.damage = damage
	super.enter()
	if state_manager.attack_listener:
		state_manager.attack_listener.reset()
	to_next_attack = false
	state_manager.attack_reset = false
	move = 0
	if attack_timer:
		attack_timer.start(anime.current_animation_length + after_attack_stiff_time)
	npc.data.attacking = true
	npc.data.hitting = true
	return


func exit(state: NpcsBaseState):
	super.exit(state)
	npc.hit_box.disable_shape()
	npc.hit_box.damage = 0
	npc.time_2_last_attack_timer.start(4096)
	if attack_timer:
		attack_timer.stop()
	npc.data.hitting = false
	if tween:
		tween.kill()
	npc.anime.stop_anime()
	npc.be_hit_times = 0
	if not next_attack:
		npc.data.attacking = false
		state_manager.attack_reset = true


func _on_attack_timer_timeout() -> void:
	if state_manager.current_state != self:
		return
	if to_next_attack and next_attack:
		state_manager.state2state(next_attack, self)
		if timeout2attack:
			Debug.dprinterr(DebugCT.dp("[%s]时间结束攻击切换" % self.name, self))
	else:
		if timeout_not2attack:
			Debug.dprinterr(DebugCT.dp("[%s]时间结束未收到攻击切换" % self.name, self))
		npc.data.attacking = false
		state_manager.attack_reset = true
		state_manager.state2state(fallback_state, self)


func physics_process(_delta: float):
	if not enable_physics:
		return
	npc.astar_move.apply_gravity(_delta)
	npc.set_up_direction(Vector2.UP)
	npc.move_and_slide()
	return
