class_name GroundState
extends BaseState
var edge_jump_flag=true

func enter():
	super.enter()
	PlayerState.double_jump_able=true
	return null

func input(event: InputEvent) -> BaseState:
	if event.is_action_pressed("jump") or event.is_action_pressed("light"):
		return jump_state
	if player.is_on_floor() :
		if Input.is_action_pressed("run"):
			if PlayerState.is_player_on_fighting:
				return fastrun_state
			else :
				return run_state
		if get_palyer_move_direction_x()!=0:
			return walk_state
		else:
			return null
	return null


