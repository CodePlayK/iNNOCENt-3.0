extends AirState
@export var toptrans_threshold:float = .1
@export_group("debug")
@export var lift2toptrans:bool = false
@export var lift2fall:bool = false
func is_animation_play():
	if player.velocity.y <= 0 and !player.is_on_floor():
		return true
	return false

func enter():
	if player.velocity.y <= 0 and !player.is_on_floor():
		PlayerState.max_height = 0
	elif player.velocity.y > -player.max_velocity_y*toptrans_threshold and !player.is_on_floor():
		return toptrans_state
	elif player.is_on_floor():
		return idle_state
	return
		
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
	else:
		if player.velocity.y > -player.max_velocity_y*toptrans_threshold:
			if lift2toptrans:Debug.dprintwarn(DebugCT.dp("[lift]切换[toptrans_state]",self))
			return toptrans_state
		elif player.velocity.y>0:
			if lift2fall:Debug.dprintwarn(DebugCT.dp("[lift]切换[fallstate]",self))
			return fall_state
	return null
