extends NpcsBaseState


func enter():
	super.enter()
	if npc.speed_map_2_animation:
		npc.speed_map_2_animation.is_enable = true
	npc.astar_move.running = true
	return


func physics_process(_delta: float):
	apply_face_from_velocity()
	if npc.velocity.y == 0 and npc.is_on_floor():
		return get_land_state()
	if npc.velocity.y > 0:
		return fall_state
	return null


func exit(_next_state: NpcsBaseState):
	npc.astar_move.running = false
	if npc.chase_weight_machine:
		npc.chase_weight_machine.exit()
	if npc.speed_map_2_animation:
		npc.speed_map_2_animation.is_enable = false
