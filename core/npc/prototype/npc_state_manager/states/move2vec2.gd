extends NpcsBaseState
## 移动到目标时，目标格相对玩家的偏移（格坐标）
@export var following_offset_vec2i: Vector2i


func enter():
	super.enter()
	npc.astar_mode = npc.ASTAR_MODE.MOVE
	npc.speed_map_2_animation.set_enabel(self, true)
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
		npc.astar.set_taget_position_mode(false)
		return idle_state
	return


func exit(next_state: NpcsBaseState):
	npc.speed_map_2_animation.set_enabel(self, false)
	if next_state not in [fall_state, lift_state]:
		npc.velocity = Vector2.ZERO
	npc.astar_move.running = false
