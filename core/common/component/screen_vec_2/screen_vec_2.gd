extends Node2D

func _process(delta: float) -> void:
	var v_size:Vector2 = Vector2(get_viewport_rect().size)
	PlayerState.player_screen_position = get_screen_transform().origin / v_size
