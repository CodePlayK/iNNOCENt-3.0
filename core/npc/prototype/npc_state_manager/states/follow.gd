extends NpcsBaseState
var following_offset_vec2i: Vector2i


func enter():
	super.enter()
	npc.on_following = true
	following_offset_vec2i = npc.following_offset_vec2i
	npc.astar_mode = npc.ASTAR_MODE.FOLLOW
	if npc.speed_map_2_animation:
		npc.speed_map_2_animation.is_enable = true
	npc.astar_move.set_astar(true)
	return


func physics_process(_delta: float):
	if not npc.astar.enable:
		return
	npc.astar_move.running = true
	var air = get_airborne_state()
	if air:
		return air
	apply_face_from_velocity()
	if npc.current_cell == npc.astar.target_current_cell and npc.is_on_floor():
		return idle_state
	npc.astar.target_offset_cell_vec2i = PlayerState.running_left_normalize * following_offset_vec2i
	return


func exit(next_state: NpcsBaseState):
	if next_state not in [fall_state, lift_state]:
		npc.velocity = Vector2.ZERO
	npc.astar_move.running = false
	if npc.speed_map_2_animation:
		npc.speed_map_2_animation.is_enable = false
	npc.face_direction.set_faced(PlayerState.face_left)
