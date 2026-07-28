extends Area2D

func blood_splash():
	if has_overlapping_areas():
		var areas = get_overlapping_areas()
		areas[0].blood_splash(self.global_position)
