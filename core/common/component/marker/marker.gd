@tool
extends Marker2D
class_name Marker
@onready var base: Sprite2D = $base

@export var color:Color:
	set(c):
		color = c
		update()
		
func update():
	if base:base.self_modulate = color
