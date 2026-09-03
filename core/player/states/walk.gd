extends GroundState


func enter():
	super.enter()
	EventBus._play_SE_LOOP("running-in-grass", true, .7)
	PlayerState.double_jump_able = true
	return null


func physics_process(delta: float) -> BaseState:
	if player.is_on_floor() and Input.is_action_pressed("run"):
		return get_run_state()
	return process_ground_motion(delta, apply_acceleration_walk)


func exit(state: BaseState):
	super.exit(state)
	EventBus._play_SE_LOOP("running-in-grass", false)
