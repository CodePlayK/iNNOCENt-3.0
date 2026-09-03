extends ColorRect
@export var health_config:HealthConfig
@export var effect_start_health_ratio:float = 0.7
@export var intensity_min_health:float = 0
@export var intensity_max_health:float = 0.7
@export var pulse_frequency_min_health:float = 0.4
@export var pulse_frequency_max_health:float = 1
@export var enable:bool = true



func _on_timer_timeout() -> void:
	if !enable:return
	sync_health_indicator()
	pass # Replace with function body.

func sync_health_indicator():
	var true_health
	var intensity
	var pulse_frequency
	if health_config.current_health > health_config.max_health*effect_start_health_ratio:
		true_health = 0
		intensity = 0
		pulse_frequency= 0
	else :
		true_health = health_config.current_health
		intensity = remap(true_health,health_config.max_health*effect_start_health_ratio,0,intensity_min_health,intensity_max_health)
		pulse_frequency = remap(true_health,health_config.max_health*effect_start_health_ratio,0,pulse_frequency_min_health,pulse_frequency_max_health)
	if material:
		material.set_shader_parameter("hurt_intensity",intensity)
		material.set_shader_parameter("pulse_frequency",pulse_frequency)
