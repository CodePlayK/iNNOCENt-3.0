extends NpcsBaseState
@export var following_offset_vec2i:Vector2i

func enter():
	super.enter()
	npc.astar_mode = npc.ASTAR_MODE.MOVE
	npc.speed_map_2_animation.set_enabel(self,true)
	npc.astar_move.set_astar(true)
	return
func physics_process(delta: float):
	if !npc.astar.enable:return
	npc.astar_move.running = true
	if npc.velocity.y>0 and !npc.is_on_floor():
		return fall_state
	if npc.velocity.y<0 and !npc.is_on_floor() :
		return lift_state
	if npc.velocity.x>0:
		npc.face_direction.set_faced(false)
	elif npc.velocity.x<0:
		npc.face_direction.set_faced(true)
	if npc.current_cell==npc.astar.target_current_cell and npc.is_on_floor():
		npc.astar.set_taget_position_mode(false)
		return idle_state
	return	
func exit(next_state:NpcsBaseState):
	npc.speed_map_2_animation.set_enabel(self,false)
	if !next_state in [fall_state,lift_state]:
		npc.velocity = Vector2.ZERO
	npc.astar_move.running = false
