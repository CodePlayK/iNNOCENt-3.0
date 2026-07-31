extends Timer
@export_file var path:String="res://core/room/common/leave/fallen_leave.tscn"
@export var num_max:int=20
@export var num_min:int=20
@onready var parallax_move_data=preload(DataState.parallax_move_data_source_path)
func _on_timeout():
	return
	EventBus._fallen_from_top(path,randi_range(num_min,num_max))
