extends NpcsStackingState
## 霸体受击时 sprite 着色持续时长（秒）
@export var bati_onhit_color_time:float = .2
@onready var timer: Timer = $Timer
## 霸体受击时播放的 HurtFX 动画名
@export var hurt_fx_name:String
func enter():
	npc.sound_effect.play_se(sound_config,self)
	npc.hurt_fx.play_fx(hurt_fx_name)
	timer.start(bati_onhit_color_time)
	npc.health.damage(state_manager.current_damage)
	return

func _on_timer_timeout() -> void:
	change_animation_color(false,false)
