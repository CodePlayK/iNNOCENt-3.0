class_name CombatAirState
extends CombatState


func input(event: InputEvent) -> BaseState:
	if event.is_action_pressed("jump") and PlayerState.double_jump_able and double_jump_state:
		PlayerState.double_jump_able = false
		return double_jump_state
	return null


func physics_process(delta: float) -> BaseState:
	move = get_movement_input_x()
	player_faced(move)
	apply_gravity(delta)
	if move == 0 or is_player_change_moving_direction():
		apply_friction(delta)
	elif Input.is_action_pressed("run"):
		apply_acceleration_run(move, delta)
	else:
		apply_acceleration_walk(move, delta)
	if not move_player():
		return null
	player.velocity = min_jump_force(player.velocity, delta)
	return null
