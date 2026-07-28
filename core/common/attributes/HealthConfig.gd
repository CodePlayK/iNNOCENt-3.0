extends Resource
class_name HealthConfig

@export var max_health:float = 10
@export var min_health:float = 0
@export var init_health:float = 10
@export var current_health:float = 10:
	set(h):
		last_health = current_health
		if h <= min_health:h = max_health
		current_health = clampf(h,min_health,max_health)
@export var last_health:float = 10
@export var health_recover_speed:float =.1
