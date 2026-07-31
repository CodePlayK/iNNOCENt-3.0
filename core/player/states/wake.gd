extends InteractiveState

var touched_floor=false

func enter():
	super.enter()
	touched_floor=false
	PlayerState.double_jump_able=true
	PlayerState.player_control_lock=true
	return null
func init_var():
	player.anime.anime_finished.connect(on_anime_finished)
	
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
	PlayerState.player_control_lock=false
	
func on_anime_finished():
	if !state_manager.current_state == self:return
	if touched_floor:
		EventBus._player_woke()
