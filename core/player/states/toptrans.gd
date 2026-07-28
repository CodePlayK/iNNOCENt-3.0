extends AirState
@export_group("debug")
@export var toptrans2fall:bool = false

func is_animation_play():
	if !player.is_on_floor():
		return true
	return false
	
func enter() -> BaseState:
	super.enter()
	if !player.is_on_floor() :
		await player.aniplayer.animation_finished
		if state_manager.current_state == self:
			if toptrans2fall:Debug.dprintwarn(DebugCT.dp("[toptrans]切换[fall_state]",self))
			return fall_state
	elif player.is_on_floor():
		return idle_state
	#elif player.velocity.y >= 0:
		#Debug.dprintwarn(DebugCT.dp("[toptrans]切换[fall_state]",self))
		#return fall_state
	return null
	
func input(event: InputEvent) -> BaseState:
	var new_state = super.input(event)
	if new_state:
		return new_state
	if Input.is_action_just_pressed("jump") and PlayerState.double_jump_able:
		PlayerState.double_jump_able=false
		return double_jump_state
	return null

func after_physics_process(delta: float)->BaseState:
	if player.is_on_floor():
		return landing_state
	return null
