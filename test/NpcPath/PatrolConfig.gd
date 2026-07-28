extends Resource
class_name PatrolConfig
var patrol_left:Marker2D
var patrol_right:Marker2D
var bot_y:float

func _init(patrol_left1:Marker2D,patrol_right1:Marker2D,bot_y1:float) -> void:
	patrol_left = patrol_left1
	patrol_right = patrol_right1
	bot_y = bot_y1
