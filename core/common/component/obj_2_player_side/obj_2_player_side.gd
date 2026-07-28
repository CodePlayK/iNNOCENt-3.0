extends Component
class_name Obj2PlayerSide
var obj
var on_player_left_normalized:int = 1
func on_master_ready(master):
	obj = master.obj

func get_on_player_left_normalized():
	if obj.global_position.x < PlayerState.player_global_position.x:
		on_player_left_normalized = -1
	else :
		on_player_left_normalized = 1
	return on_player_left_normalized
