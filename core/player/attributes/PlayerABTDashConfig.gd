extends Resource
class_name PlayerABTDashConfig
@export_range(0,5.0) var dash_cooldown:float = 1.0
@export var dash_time:float = 1

func get_attribute_txt():
	return ""
func get_cooldown():
	return dash_cooldown
func get_during():
	return dash_time
