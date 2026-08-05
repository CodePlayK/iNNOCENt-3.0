extends Weight
@export var distance_max:float
@export var distance_min:float
var distance

func process(obj) -> void:
	distance = abs(obj.global_position.x - PlayerState.player_player.global_position.x)
	if distance < distance_min or distance > distance_max:
		weight = impossible_weight
	else :
		weight = clamp(remap(distance,distance_min,distance_max,confirmed_weight,impossible_weight),impossible_weight,confirmed_weight)
