extends Area2D
@onready var blood: Node2D = $Blood
func blood_splash(pos:Vector2):
	var blood_new = blood.duplicate()
	get_parent().add_child(blood_new)
	var p = get_parent().to_local(pos)
	blood_new.global_position = pos
	blood_new.play()
