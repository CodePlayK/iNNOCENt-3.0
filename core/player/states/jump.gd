class_name JumpState
extends BaseState
	
func physics_process(delta: float) -> BaseState:
	move=get_movement_input_x()
	player_faced(move)
	apply_gravity(delta)
	apply_acceleration_walk(move,delta)
	player.set_up_direction(Vector2.UP)
	player.velocity.y = -player.jump_speed
	player.move_and_slide()
	if player.is_on_floor():
		if move != 0:
			if Input.is_action_pressed("run"):
				return run_state
			return walk_state
		return idle_state
	else:
		if player.velocity.y > 0:
			return fall_state
		else:
			return lift_state
