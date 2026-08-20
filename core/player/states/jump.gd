class_name JumpState
extends BaseState


func physics_process(delta: float) -> BaseState:
	move = get_movement_input_x()
	player_faced(move)
	apply_gravity(delta)
	apply_acceleration_walk(move, delta)
	player.velocity.y = -player.jump_speed
	if not move_player():
		return null
	if player.is_on_floor():
		if move != 0:
			if Input.is_action_pressed("run"):
				return run_state
			return walk_state
		return idle_state
	return get_airborne_state()
