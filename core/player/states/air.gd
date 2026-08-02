class_name AirState
extends BaseState

func input(event: InputEvent) -> BaseState:
	if Input.is_action_just_pressed("jump") and PlayerState.double_jump_able:
		PlayerState.double_jump_able=false
		return double_jump_state
	return null

func physics_process(delta: float) -> BaseState:

	move=get_movement_input_x()
	player_faced(move)
	apply_gravity(delta)
	if move==0 or is_player_change_moving_direction():
		apply_friction(delta)
	else:
		if Input.is_action_pressed("run"):
			apply_acceleration_run(move,delta)
		else:
			apply_acceleration_walk(move,delta)
	player.set_velocity(player.velocity)
	player.set_up_direction(Vector2.UP)
	if !is_instance_valid(player) or player.get_world_2d() == null:
		return idle_state
	player.move_and_slide()
	player.velocity=min_jump_force(player.velocity,delta)
	return null
