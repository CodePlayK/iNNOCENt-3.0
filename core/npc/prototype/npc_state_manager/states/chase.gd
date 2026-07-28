extends NpcsCombatState
class_name NpcsChaseState
@export var chase_speed:float=300
var chase_speed_r:float
@export var chase_distance:int=30
@export var lost_distance:int=500
@onready var timer: Timer = $Timer
var speed_map_2_animation
var face_direction: FaceDirection

func init_var():
	speed_map_2_animation = npc.speed_map_2_animation
	face_direction = npc.face_direction

func enter():
	super.enter()
	npc.astar_mode = npc.ASTAR_MODE.CHASE
	timer.start()
	chase_speed_r=chase_speed*randf_range(.8,1.2)
	speed_map_2_animation.set_enabel(self,true)
	npc.astar_move.set_astar(true)
	return
	
func physics_process(delta: float):
	if !npc.chase_range.has_overlapping_bodies():
		npc.astar_move.running = true
	if npc.velocity.y>0 and !npc.is_on_floor():
		return fall_state
	if npc.velocity.y<0 and !npc.is_on_floor() :
		return lift_state
	if npc.velocity.x>0:
		npc.face_direction.set_faced(false)
	elif npc.velocity.x<0:
		npc.face_direction.set_faced(true)
	return
		
func _on_timer_timeout() -> void:
	if state_manager.current_state == self :
		if npc.is_on_floor() :
			if npc.chase_range.has_overlapping_bodies():
				state_manager.state2state(npc.chase_weight_machine.process(self),self)

func exit(next_state:NpcsBaseState):
	timer.stop()
	if !next_state in [fall_state,lift_state]:
		npc.velocity = Vector2.ZERO
	npc.astar_move.running = false
	npc.chase_weight_machine.exit()
	speed_map_2_animation.set_enabel(self,false)
