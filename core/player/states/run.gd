extends GroundState

func  pre_animation() -> BaseState:
	return process_ground_motion(get_physics_process_delta_time(), apply_acceleration_run)
	
func enter():
	super.enter()
	EventBus._play_SE_LOOP("running-in-grass", true, 1)
	PlayerState.double_jump_able = true
	return null


func physics_process(delta: float) -> BaseState:
	return process_ground_motion(delta, apply_acceleration_run)


func exit(state: BaseState):
	super.exit(state)
	EventBus._play_SE_LOOP("running-in-grass", false)
