extends GroundState


func input(_event: InputEvent) -> BaseState:
	return null


func is_animation_play():
	return PlayerState.max_height > 150 and not PlayerState.last_state is PlayerAttackState


func enter() -> BaseState:
	if PlayerState.max_height > 150 and not PlayerState.last_state is PlayerAttackState:
		await player.aniplayer.animation_finished
	move = get_movement_input_x()
	if move != 0 and not is_player_blocked():
		if Input.is_action_pressed("run"):
			return run_state
		return walk_state
	return idle_state


func physics_process(delta: float) -> BaseState:
	return process_ground_motion(delta, apply_acceleration_walk, false)
