extends GroundState
@export var following_offset_vec2i:Vector2i

func enter():
	super.enter()
	player.astar_mode = player.ASTAR_MODE.MOVE
	#player.speed_map_2_animation.set_enabel(self,true)
	player.astar_move.set_astar(true)
	return
	
func physics_process(_delta: float):
	if !player.astar.enable:return
	player.astar_move.running = true
	var airborne := get_airborne_state()
	if airborne:
		return airborne
	if player.velocity.x>0:
		player.face_direction.set_faced(false)
	elif player.velocity.x<0:
		player.face_direction.set_faced(true)
	if player.current_cell==player.astar.target_current_cell and player.is_on_floor():
		player.astar.set_taget_position_mode(false)
		return idle_state
	return
		
func exit(next_state:BaseState):
	#player.speed_map_2_animation.set_enabel(self,false)
	if !next_state in [fall_state,lift_state]:
		player.velocity = Vector2.ZERO
	player.astar_move.running = false
