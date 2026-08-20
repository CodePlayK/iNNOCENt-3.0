extends AirState


func is_animation_play():
	return player.velocity.y >= 0 and not player.is_on_floor()


func enter() -> BaseState:
	if player.velocity.y >= 0 and not player.is_on_floor():
		return null
	return idle_state


func after_physics_process(_delta: float) -> BaseState:
	if player.is_on_floor():
		return landing_state
	return null
