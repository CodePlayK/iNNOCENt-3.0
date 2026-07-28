extends Resource
class_name PlayerABTDenseConfig
@export var dense_time:float = .5
@export var dense_cooldown:float = 1.4
@export var dense_gravity_scale:float = 12.0

func get_attribute_txt():
	return "硬化时重力增加倍率:%s" %dense_gravity_scale
func get_cooldown():
	return dense_cooldown
func get_during():
	return dense_time
