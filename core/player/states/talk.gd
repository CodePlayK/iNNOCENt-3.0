extends InteractiveState
var touched_floor=false

func enter():
	super.enter()
	touched_floor=false
	PlayerState.double_jump_able=true
	PlayerState.player_control_lock=true
	return null
	
func input(event: InputEvent) -> BaseState:
	return null

func physics_process(delta: float) -> BaseState:
	if touched_floor:return null
	player.velocity.x=0
	apply_gravity(delta)
	player_faced(move)
	player.set_up_direction(Vector2.UP)
	player.move_and_slide()
	if player.is_on_floor():
		touched_floor=true
	return null 

func exit(state:BaseState):
	super.exit(state)
