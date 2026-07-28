extends NpcsBaseState
@export_group("运动配置")
@export var enable_physics:bool = true
@export var follow_distance:int = 1
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
	if state_manager.current_state == self:
		if npc.astar.get_manhattan_distance()>follow_distance and npc.current_cell!=npc.astar.target_current_cell:
			state_manager.state2state(follow_state,self)
