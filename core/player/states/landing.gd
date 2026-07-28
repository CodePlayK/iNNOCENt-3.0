extends GroundState
func input(event: InputEvent) -> BaseState:
	return null

func is_animation_play():
	if PlayerState.max_height>150 and !PlayerState.last_state is PlayerAttackState:
		return true
	return false

func enter() -> BaseState:
	if PlayerState.max_height>150 and !PlayerState.last_state is PlayerAttackState:
		await player.aniplayer.animation_finished
	return idle_state

func physics_process(delta: float) -> BaseState:
	move = get_movement_input_x()
	if !player.is_on_floor() and player.velocity.y<=0:
		return lift_state
	if !player.is_on_floor() and player.velocity.y>0:
		return fall_state
	player_faced(move)
	apply_gravity(delta)
	if move==0 or is_player_change_moving_direction():
		apply_friction(delta)
	else:
		apply_acceleration_walk(move,delta)
	player.set_velocity(player.velocity)
	player.set_up_direction(Vector2.UP)
	player.move_and_slide()
	min_jump_force(player.velocity,delta)
	return null
