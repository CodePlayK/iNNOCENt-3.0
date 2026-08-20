extends GroundState

@onready var timer: Timer = $Timer
@export var dash_config: PlayerABTDashConfig

var current_dash_time: float = 0
var enable: bool = true


func pre_enter() -> bool:
	return enable


func enter():
	super.enter()
	if Input.is_action_pressed("move_left"):
		player_faced(-1)
	elif Input.is_action_pressed("move_right"):
		player_faced(1)
	timer.start(dash_config.dash_cooldown)
	enable = false
	player.hurt_box.disable_hit()
	current_dash_time = dash_config.dash_time
	return null


func input(_event: InputEvent) -> BaseState:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		return jump_state
	if current_dash_time > 0:
		return null
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("run"):
			return run_state
		return walk_state
	return null


func physics_process(delta: float) -> BaseState:
	current_dash_time -= delta
	apply_gravity(delta)
	apply_acceleration_dash(PlayerState.face_left_normalize, delta)
	if not move_player():
		return null
	if current_dash_time <= 0:
		return PlayerState.get_last_normal_state()
	return null


func exit(state: BaseState):
	super.exit(state)
	player.velocity.x = 0
	player.hurt_box.enable_hit()


func _on_timer_timeout() -> void:
	enable = true
