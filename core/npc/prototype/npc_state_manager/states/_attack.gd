@icon("res://core/common/resource/icon/Editor3DHandle.svg")
extends NpcsBaseState
##玩家攻击状态
class_name NpcsAttackState
##下一段攻击
@export_category("配置")
@export_group("伤害")
@export var damage:float = 1.0
@export_group("基础配置")
@export var next_attack:NpcsAttackState
@export var fallback_state:NpcsBaseState
##在经过攻击时长多少比例后,可以切换到下一攻击
@export_range(0,1.0) var to_next_attack_threshold:float = .2
##攻击后的硬直时间
@export_range(0,5.0) var after_attack_stiff_time:float = .5
##攻击后可以切换到下一段攻击的时间
@export_range(0,2.0) var listen_next_attack_time:float = 1
###攻击动画名,默认为状态名
#@export var ani_name:String
##声音
@export var sound_name:String = "slash7"
@export_group("运动配置")
##攻击状态中是否允许移动
@export var moveable:bool = true
@export var change_face_able:bool = true
@export var enable_physics:bool = true
##攻击状态中的移动速度比率:相对于行走速度
@export_range(0,2.0) var move_speed_scale_to_walk:float = 1.0
@export var marker: Marker
@export_group("Debug")
@export var attack_input_receive:bool = false
@export var start_listener:bool = false
@export var timeout2attack:bool = false
@export var timeout_not2attack:bool = false
var tween
##实际的攻击动画耗时,包括僵直
@onready var attack_timer: Timer = $attackTimer
##到下一段攻击
var to_next_attack:bool = false
@onready var bloodking_attack_time_event: Node = %BloodkingAttackTime

func _ready() -> void:
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)

func enter():
	bloodking_attack_time_event.add_time()
	npc.hit_box.disable_shape()
	npc.hit_box.damage = damage
	super.enter()
	state_manager.attack_listener.reset()
	to_next_attack = false
	state_manager.attack_reset = false
	move = 0
	attack_timer.start(anime.current_animation_length+after_attack_stiff_time)
	npc.data.attacking=true
	npc.data.hitting=true
	return
	
func exit(state:NpcsBaseState):
	super.exit(state)
	npc.hit_box.disable_shape()
	npc.hit_box.damage = 0
	npc.time_2_last_attack_timer.start(4096)
	attack_timer.stop()
	npc.data.hitting=false
	if tween:tween.kill()
	npc.anime.stop_anime()
	npc.be_hit_times = 0
	npc.bating = false
	
	#当没有执行切换到下一段攻击,且有配置下一段攻击,或者退出的下一个状态不是攻击状态时
	#开启监听
	if !next_attack:
		npc.data.attacking = false
		state_manager.attack_reset = true
	if !to_next_attack and next_attack or !state is NpcsAttackState:
		if start_listener:Debug.dprinterr(DebugCT.dp("[%s]状态启动监听" %self.name,self,))
		#state_manager.attack_listener.listen_to_state(next_attack,listen_next_attck,listen_next_attack_time,self)

		
##攻击动画结束,包括僵直		
func _on_attack_timer_timeout() -> void:
	#如果当前处于硬化状态或者已经切换到其他状态则跳过
	if state_manager.current_state != self:
		return
	#正在攻击动画中按下且有下一段攻击时则直接切换
	if to_next_attack and next_attack:
		state_manager.state2state(next_attack,self)
		if timeout2attack:Debug.dprinterr(DebugCT.dp("[%s]时间结束攻击切换" %self.name,self,))
	elif !to_next_attack and next_attack:#如果未主动切换下一攻击且当前有下一攻击,则切换到上一个正常状态
		if timeout_not2attack:Debug.dprinterr(DebugCT.dp("[%s]时间结束未收到攻击切换" %self.name,self,))
		state_manager.state2state(fallback_state,self)	
	elif !next_attack:#如果为终结攻击,则切换到上一正常状态,且重置player攻击标记与攻击序列重置标记
		npc.data.attacking = false
		state_manager.attack_reset = true
		state_manager.state2state(fallback_state,self)	
	pass	
func physics_process(delta: float):
	if !enable_physics:return
	npc.astar_move.apply_gravity(delta)
	npc.set_up_direction(Vector2.UP)
	npc.move_and_slide()
	return
