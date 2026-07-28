extends Line2D
@export var target:Node2D
@export var from:Node2D
@export var enable:bool = true:
	set(f):
		enable = f
		if f:
			show()
		else :
			hide()


func _physics_process(delta: float) -> void:
	if enable and target and from:
		set_point_position(0,from.get_screen_transform().origin)
		set_point_position(1,target.get_screen_transform().origin)
