extends Resource
class_name PlayerABTLightConfig
@export var light_gravity_scale:float=3
@export var light_time:float = 3.0
@export var light_cooldown:float = 5.0


func get_attribute_txt():
	return "轻化时重力降低倍率:%s" %light_gravity_scale
func get_cooldown():
	return light_cooldown
func get_during():
	return light_time
