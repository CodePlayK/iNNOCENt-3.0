extends Resource
class_name StaminaConfig
@export var max_stamina:float = 200
@export var last_stamina:float = 200
##能量条恢复速度
@export var stamina_recover_speed:float =10
##能量条
@export var current_stamina:float = 200:
	set(h):
		var e = clamp(h,0,max_stamina)
		if e == max_stamina:
			current_stamina = e
			return
		last_stamina = current_stamina
		current_stamina = e
