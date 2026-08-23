@icon("res://core/common/resource/icon/ReflectionProbe.svg")
extends Node
class_name Master
@export var obj: Node
@export var connects:Array[Node]
@onready var timer: Timer = $Timer

signal master_ready

func _init() -> void:
	obj=get_parent()

func _ready() -> void:
	obj.ready.connect(on_obj_ready)
	
func on_obj_ready():
	init_node()
	
func init_node():
	on_master_ready()
	for node in connects:
		if node and node.has_method("on_master_ready"):
			node.on_master_ready(self)

func _on_timer_timeout() -> void:
	init_node()

func on_master_ready():
	return
