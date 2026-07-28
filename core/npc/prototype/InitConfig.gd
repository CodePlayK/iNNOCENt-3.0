extends Node
class_name NpcInitConfig
##巡逻范围右边界
@export var patrol_right:Marker2D
##巡逻范围左边界
@export var patrol_left:Marker2D

func _init(patrol_left1:Marker2D,patrol_right1:Marker2D) -> void:
	patrol_left = patrol_left1
	patrol_right = patrol_right1
