extends NpcsBaseState

@onready var timer: Timer = $Timer
var speed_map_2_animation
var face_direction: FaceDirection

func init_var():
	speed_map_2_animation = npc.speed_map_2_animation
	face_direction = npc.face_direction
	timer.timeout.connect(_on_timer_timeout)

func enter():
	super.enter()
	timer.start()
	speed_map_2_animation.set_enabel(self,true)
	npc.astar_move.running = true
	return
func physics_process(delta: float):
	if npc.velocity.x>=0:
		npc.face_direction.set_faced(false)
	else :
		npc.face_direction.set_faced(true)
	if npc.velocity.y==0 and npc.is_on_floor():
		match npc.astar_mode:
			npc.ASTAR_MODE.FOLLOW:
				return follow_state
			npc.ASTAR_MODE.MOVE:
				return move2vec2_state
			npc.ASTAR_MODE.CHASE:
				return chase_state
	return
func _on_timer_timeout() -> void:
	return
	if state_manager.current_state == self and npc.is_on_floor() and npc.chase_range.has_overlapping_bodies():
		state_manager.state2state(npc.chase_weight_machine.process(self),self)

func exit(NpcsBaseState):
	npc.astar_move.running = false
	timer.stop()
	npc.chase_weight_machine.exit()
	speed_map_2_animation.set_enabel(self,false)
