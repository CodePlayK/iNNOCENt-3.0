extends NpcsCombatState
## 闪避位移距离（远离玩家方向）
@export var dodge_distance:float
## 闪避位移所用时间（秒）
@export var dodge_time:float
## 闪避冷却时间（秒），冷却结束前不能再次闪避
@export var cooldown:float
@onready var timer: Timer = $Timer
var tween:Tween

func pre_enter() -> bool:
	return npc.dodgeable

func enter():
	super.enter()
	npc.hurt_box.disable_hit()
	var side = sign(PlayerState.player_player.global_position.x - npc.global_position.x)
	npc.face_direction.set_faced(side==-1)
	npc.dodgeable = false
	tween = npc.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(npc,"global_position",Vector2(npc.global_position.x-side*dodge_distance,npc.global_position.y),dodge_time)
	tween.parallel().tween_property(npc,"modulate",Color("ffffff2a"),dodge_time*0.3)
	tween.tween_property(npc,"modulate",Color("ffffffff"),dodge_time*0.7)
	await tween.finished
	timer.start(cooldown-dodge_time)
	return chase_state

func exit(state:NpcsBaseState):
	npc.hurt_box.enable_hit()
	tween.kill()
	npc.modulate = Color("ffffffff")
func _on_timer_timeout() -> void:
	npc.dodgeable = true
	
func physics_process(delta: float):
	npc.astar_move.apply_gravity(delta)
	npc.set_up_direction(Vector2.UP)
	npc.move_and_slide()
	return
