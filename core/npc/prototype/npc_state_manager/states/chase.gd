extends NpcsCombatState
class_name NpcsChaseState
## 追逐水平速度（实际速度会再乘 0.8~1.2 随机）
@export var chase_speed: float = 300
var chase_speed_r: float
## 与玩家距离小于该值时停止逼近（保持间距）
@export var chase_distance: int = 30
## 与玩家距离大于该值时判定丢失目标，退出追逐
@export var lost_distance: int = 500
@onready var timer: Timer = $Timer


func enter():
	super.enter()
	npc.astar_mode = npc.ASTAR_MODE.CHASE
	timer.start()
	chase_speed_r = chase_speed * randf_range(.8, 1.2)
	if npc.speed_map_2_animation:
		npc.speed_map_2_animation.is_enable = true
	npc.astar_move.set_astar(true)
	return


func physics_process(_delta: float):
	if not npc.chase_range.has_overlapping_bodies():
		npc.astar_move.running = true
	var air = get_airborne_state()
	if air:
		return air
	apply_face_from_velocity()
	return


func _on_timer_timeout() -> void:
	if state_manager.current_state != self:
		return
	if npc.is_on_floor() and npc.chase_range.has_overlapping_bodies():
		state_manager.state2state(npc.chase_weight_machine.process(self), self)


func exit(next_state: NpcsBaseState):
	timer.stop()
	if next_state not in [fall_state, lift_state]:
		npc.velocity = Vector2.ZERO
	npc.astar_move.running = false
	npc.chase_weight_machine.exit()
	if npc.speed_map_2_animation:
		npc.speed_map_2_animation.is_enable = false
