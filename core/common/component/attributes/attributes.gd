@icon("res://addons/at-icons/control/battery_high.svg")

extends Node
class_name Attributes

func _ready() -> void:
	EventBus.on_new_game.connect(reset)
	
func reset():
	pass
