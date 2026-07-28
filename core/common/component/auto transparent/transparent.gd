extends Node
@onready var obj = $".."

func _process(delta: float) -> void:
	obj.material.set_shader_parameter("player_position",PlayerState.player_screen_position)
