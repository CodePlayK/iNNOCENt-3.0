extends Resource
class_name PlayerABTDenseConfig
## 硬化状态持续时长（秒）
@export var dense_time:float = .5
## 硬化冷却时间（秒），冷却结束前不能再次硬化
@export var dense_cooldown:float = 1.4
## 硬化期间重力与下落速度上限的倍率（越大落得越快）
@export var dense_gravity_scale:float = 12.0

func get_attribute_txt():
	return "硬化时重力增加倍率:%s" %dense_gravity_scale
func get_cooldown():
	return dense_cooldown
func get_during():
	return dense_time
