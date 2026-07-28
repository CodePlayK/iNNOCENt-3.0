extends Node2D
@onready var health_bar: UIbar = $HealthBar
@onready var damage_num: Node2D = $HurtFX/DamageNum

func on_health_init(health:Health) -> void:
	health_bar.bar_max_value = health.max_health
	health_bar.bar_min_value = health.min_health
	health_bar.current_value = health.current_health
	health_bar.preset()
	
func on_health_damaged(health:Health):
	damage_num.emit_num(health.current_damage)
	health_bar.bar_decrease(health.current_health)
	
func on_health_healed(health):
	health_bar.bar_grow(health.current_health)
