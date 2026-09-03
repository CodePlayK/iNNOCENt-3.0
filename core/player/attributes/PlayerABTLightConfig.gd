extends Resource
class_name PlayerABTLightConfig
## 轻化期间重力与下落速度上限的除数（越大越轻、落得越慢）
@export var light_gravity_scale:float=3
## 轻化状态持续时长（秒）
@export var light_time:float = 3.0
## 轻化冷却时间（秒），冷却结束前不能再次轻化
@export var light_cooldown:float = 5.0


func get_attribute_txt():
	return "轻化时重力降低倍率:%s" %light_gravity_scale
func get_cooldown():
	return light_cooldown
func get_during():
	return light_time
