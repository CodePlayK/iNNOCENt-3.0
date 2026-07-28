extends BaseState

@onready var lightTimer=$lightTimer
@export var ABT_light_config:PlayerABTLightConfig

@onready var light_cooldown_timer: Timer = $lightCooldownTimer

func pre_enter() -> bool:
	if PlayerState.lightable_flag and !PlayerState.ability_lock:
		player.max_velocity_y=player.max_velocity_y/ABT_light_config.light_gravity_scale
		player.gravity=player.gravity/ABT_light_config.light_gravity_scale
		lightTimer.start(ABT_light_config.light_time)
		light_cooldown_timer.start(ABT_light_config.light_cooldown)
		PlayerState.lightable_flag=false
		PlayerState.light_flag=true
	return false
	
func enter():
	super.enter()
	return
	
func exit(state:BaseState):
	super.exit(state)
	PlayerState.light_flag=true
	
func _on_light_timer_timeout():
	player.max_velocity_y=player.max_velocity_y*ABT_light_config.light_gravity_scale
	player.gravity=player.gravity*ABT_light_config.light_gravity_scale
	PlayerState.light_flag=false

func _on_light_cooldown_timer_timeout() -> void:
	PlayerState.lightable_flag=true
