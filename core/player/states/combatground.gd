extends CombatState
class_name CombatGroundState

var edge_jump_flag = true


func enter():
	super.enter()
	PlayerState.double_jump_able = true
	return null


func input(event: InputEvent) -> BaseState:
	if event.is_action_pressed("jump"):
		return combatjump_state
	if not player.is_on_floor():
		return null
	if Input.is_action_pressed("run"):
		return get_run_state()
	if get_player_move_direction_x() != 0:
		return combatrun_state
	return null


func get_run_state() -> BaseState:
	return combatfastrun_state if PlayerState.is_player_on_fighting else combatrun_state


func process_ground_motion(delta: float, accel: Callable, to_idle_when_stopped: bool = true) -> BaseState:
	move = get_movement_input_x()
	var airborne := get_airborne_state()
	if airborne:
		return airborne
	player_faced(move)
	apply_gravity(delta)
	apply_horizontal(delta, accel)
	if not move_player():
		return null
	min_jump_force(player.velocity, delta)
	if to_idle_when_stopped and player.velocity.x == 0 and move == 0:
		return combatidle_state
	return null
