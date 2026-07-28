extends Weight
@export var time_max:float
@export var time_min:float
var time

func process(obj) -> void:
	time = 4096 - obj.time_2_last_attack_timer.time_left
	var rmap = remap(time,time_min,time_max,impossible_weight,confirmed_weight)
	weight = clamp(rmap,confirmed_weight,impossible_weight)
