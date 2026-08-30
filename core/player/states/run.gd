extends GroundState

func  pre_animation() -> BaseState:
	if player.velocity.x == 0 and move == 0 :
		return idle_state
	return null
	
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
