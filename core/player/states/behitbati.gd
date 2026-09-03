extends StackingState
## 霸体受击时 sprite 着色持续时长（秒）
@export var bati_onhit_color_time:float = .2
@onready var timer: Timer = $Timer

func enter():
	timer.start(bati_onhit_color_time)
	player.health.damage_health(state_manager.current_damage)
	return null

func _on_timer_timeout() -> void:
	change_animation_color(false,false)
