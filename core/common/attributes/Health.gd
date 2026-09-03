extends Attributes
@export var health_config:HealthConfig


func _physics_process(delta: float) -> void:
	healing(health_config.health_recover_speed*delta)
	
func damage_health(damage,update:bool = true):
	health_config.current_health-=damage
	if owner:
		owner.ui.on_health_damaged()

func healing(heal,update:bool = true):
	health_config.current_health+=heal
	if owner:
		owner.ui.on_health_healed()

func reset():
	health_config.current_health = health_config.max_health
	
