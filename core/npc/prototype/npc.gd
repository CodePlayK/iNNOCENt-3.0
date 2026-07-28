extends Npcs

func enable_all_interact(flag):
	if on_combat or on_fighting:return
	enable_self(flag)

func enable_player_detection(flag):
	player_detection.set_deferred("monitoring",flag)
	player_detection.set_deferred("monitorable",flag)
	
func enable_self(flag):
	set_deferred("monitoring",flag)
	set_deferred("monitorable",flag)
	
func enable_hitbox(flag:bool):
	hit_box.set_enable(flag)
