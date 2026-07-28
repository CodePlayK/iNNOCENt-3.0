extends Weight

func process(obj) -> void:
	if !PlayerState.hitting:
		weight = impossible_weight
	else :
		weight = confirmed_weight
