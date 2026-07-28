extends Weight

func process(obj) -> void:
	if weight_machine.obj.dodgeable:
		weight = confirmed_weight
	else :
		weight = impossible_weight
