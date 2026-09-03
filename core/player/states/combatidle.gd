extends CombatGroundState
var to_struggle_state:bool
var waiting_anime_finished:bool


func enter():
	super.enter()
	PlayerState.double_jump_able = true
	return null


func input(event: InputEvent) -> BaseState:
	if event.is_action_pressed("jump"):
		return combatjump_state
	return null


func physics_process(delta: float) -> BaseState:
	move = get_movement_input_x()
	apply_gravity(delta)
	apply_acceleration_walk(move, delta)
	player_faced(move)
	if not move_player():
		return null
	return get_airborne_state()


func after_physics_process(_delta: float) -> BaseState:
	move = get_movement_input_x()
	if move != 0 and not is_player_blocked():
		if Input.is_action_pressed("run"):
			return combatfastrun_state
		return combatrun_state
	return null


func exit(state: BaseState):
	super.exit(state)
