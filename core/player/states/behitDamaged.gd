extends behit
class_name BehitDamagedState
@onready var stiff_timer: Timer = $StiffTimer
@onready var protect_timer: Timer = $ProtectTimer
@export var stiff_time=.3
@export_range(0,5.0) var protect_time=.3
var enable:bool = true

func pre_enter() -> bool:
	return enable

func enter():
	super.enter()
	player.health.damage_health(state_manager.current_damage)
	enable = false
	stiff_timer.start(stiff_time)
	return null

func _on_stiff_timer_timeout():
	if state_manager.current_state!=self:return
	state_manager.state2state(PlayerState.get_last_normal_state(),self)
	
func exit(state:BaseState):
	super.exit(state)
	stiff_timer.stop()
	protect_timer.start(protect_time)
	if protect_time == 0:
		enable = true

func _on_protect_timer_timeout() -> void:
	enable = true
