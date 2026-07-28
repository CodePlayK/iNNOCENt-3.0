extends Node2D
var obj

func on_master_ready(master):
	obj = master.obj

func _process(delta: float) -> void:
	if !obj:return
	var v_size:Vector2 = Vector2(get_viewport_rect().size)
	obj.screen_position = get_screen_transform().origin / v_size
