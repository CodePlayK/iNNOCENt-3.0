extends GroundState


func enter():
	super.enter()
	PlayerState.double_jump_able = true
	return null


func physics_process(delta: float) -> BaseState:
	return process_ground_motion(delta, apply_acceleration_fastrun)


func exit(state: BaseState):
	super.exit(state)
