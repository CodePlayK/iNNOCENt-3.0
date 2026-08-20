extends Resource
class_name PlayerABTDashConfig
## 冲刺冷却时间（秒），冷却结束前不能再次冲刺
@export_range(0,5.0) var dash_cooldown:float = 1.0
## 冲刺位移持续时长（秒）
@export var dash_time:float = 1

func get_attribute_txt():
	return ""
func get_cooldown():
	return dash_cooldown
func get_during():
	return dash_time
