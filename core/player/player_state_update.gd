extends Timer
var player_pos_x_a:float

func _on_timeout_0_1() -> void:
	pass # Replace with function body.

func _on_timeout_1() -> void:
	if !PlayerState.current_player:return
	if player_pos_x_a==PlayerState.current_player.position.x:return
		#当player向右跑
	if player_pos_x_a<PlayerState.current_player.position.x:
		PlayerState.running_left_normalize=1
	else:
		PlayerState.running_left_normalize=-1
	player_pos_x_a=PlayerState.current_player.position.x
