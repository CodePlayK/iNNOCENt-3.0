extends NpcsBaseState
@export_group("运动配置")
@export var enable_physics:bool = true
@onready var follow_timer: Timer = $FollowTimer

func enter():
	npc.astar_move.set_astar(false)
	match npc.astar_mode:
		npc.ASTAR_MODE.FOLLOW:
			follow_timer.start()
		npc.ASTAR_MODE.MOVE:
			pass
		npc.ASTAR_MODE.CHASE:
			pass
	return	

func physics_process(delta: float):
	if !enable_physics:return
	npc.astar_move.apply_gravity(delta)
	npc.set_up_direction(Vector2.UP)
	npc.move_and_slide()
	return
func exit(next_state:NpcsBaseState):
	follow_timer.stop()
	
func _on_follow_timer_timeout() -> void:
	if !npc.on_following:return
	npc.astar.target_offset_cell_vec2i = PlayerState.running_left_normalize*npc.following_offset_vec2i
	if state_manager.current_state == self:
		if npc.astar.only_update_on_floor and !PlayerState.is_player_on_floor():return
		if !npc.follwing_idel_range.has_overlapping_bodies():
			npc.astar_move.set_astar(true)
			if npc.current_cell!=npc.astar.target_current_cell:
				state_manager.state2state(follow_state,self)
